import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("download_models", Path(__file__).with_name("download_models.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class AssetPolicyTests(unittest.TestCase):
    """Local policy tests, NOT native model inference or a voice-quality test."""

    def test_only_model_assets_selected(self):
        metadata = {"siblings": [
            {"rfilename": "config.json", "size": 3},
            {"rfilename": "speech_tokenizer/model.safetensors", "size": 8},
            {"rfilename": "private.wav", "size": 20},
            {"rfilename": "run.py", "size": 20},
        ]}
        self.assertEqual(
            [x["rfilename"] for x in module.selected_files(metadata)],
            ["config.json", "speech_tokenizer/model.safetensors"])

    def test_path_traversal_rejected(self):
        for name in ["../model.json", "/tmp/model.json", "x\\model.json"]:
            with self.subTest(name=name), self.assertRaises(ValueError):
                module.selected_files({"siblings": [{"rfilename": name, "size": 1}]})

    def test_entire_huge_repo_cannot_be_downloaded(self):
        with self.assertRaises(ValueError):
            module.selected_files({"siblings": [{"rfilename": "model.safetensors", "size": 85_000_000_000}]})

    def test_pocket_and_customvoice_cannot_be_substituted(self):
        for kind in ["pocketConversion", "pocketOriginal", "CustomVoice"]:
            with self.subTest(kind=kind), self.assertRaises(ValueError):
                module.download(kind, "/unused", {})

    def test_gate_and_revision_fail_before_any_asset_download(self):
        pins = {"models": {"qwenBase": {
            "repository": "example/test", "revision": "a" * 40,
        }}}
        for metadata in [
            {"sha": "a" * 40, "gated": "auto"},
            {"sha": "b" * 40, "gated": False},
        ]:
            with self.subTest(metadata=metadata), patch.object(module, "get_json", return_value=metadata):
                with self.assertRaises(ValueError):
                    module.download("qwenBase", "/unused", pins)

    def test_primary_sha_must_match_the_pinned_weight(self):
        pins = {"models": {"qwenBase": {
            "repository": "example/test", "revision": "a" * 40,
            "file": "model.safetensors", "sha256": "expected", "bytes": 3,
        }}}
        metadata = {"sha": "a" * 40, "gated": False, "siblings": [{
            "rfilename": "model.safetensors", "size": 3, "lfs": {"sha256": "wrong"},
        }]}
        with patch.object(module, "get_json", return_value=metadata), self.assertRaises(ValueError):
            module.download("qwenBase", "/unused", pins)

    def test_fixture_download_verifies_all_bytes_and_correct_variant(self):
        # Small artificial bytes, never represented as actual model weights.
        import hashlib
        payloads = {
            "model.safetensors": b"fixture weights",
            "speech_tokenizer/model.safetensors": b"fixture codec",
            "config.json": json.dumps({"tts_model_type": "base"}).encode(),
        }
        sha = lambda value: hashlib.sha256(value).hexdigest()
        entries = [{"rfilename": name, "size": len(data), "lfs": {"sha256": sha(data)}}
                   for name, data in payloads.items()]
        pins = {"models": {
            "qwenBase": {"repository": "test/fixture", "revision": "a" * 40,
                         "file": "model.safetensors", "sha256": sha(payloads["model.safetensors"]),
                         "bytes": len(payloads["model.safetensors"])},
            "qwenCodec": {"sha256": sha(payloads["speech_tokenizer/model.safetensors"])},
        }}
        metadata = {"sha": "a" * 40, "gated": False, "siblings": entries}
        def response(url, timeout):
            return io.BytesIO(payloads[url.split("/" + "a" * 40 + "/")[1]])
        with tempfile.TemporaryDirectory() as root, patch.object(module, "get_json", return_value=metadata):
            destination = Path(root) / "new"
            with patch.object(module.urllib.request, "urlopen", side_effect=response):
                with contextlib.redirect_stdout(io.StringIO()):
                    module.download("qwenBase", destination, pins)
            lock = json.loads((destination / "spike-asset-lock.json").read_text())
            self.assertEqual(len(lock["assets"]), 3)
            self.assertEqual((destination / "model.safetensors").read_bytes(), payloads["model.safetensors"])


if __name__ == "__main__":
    unittest.main()
