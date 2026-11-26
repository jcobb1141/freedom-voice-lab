# Project FREEDOM — Native Voice Lab notices

This app is a modified version of PocketPal AI.

- PocketPal AI — MIT License, Copyright (c) 2024 Asghar Ghorbani. https://github.com/a-ghorbani/pocketpal-ai
  The original LICENSE file must stay in the repository and in any redistribution.

Selected engine libraries declare MIT licenses: llama.rn (llama.cpp), whisper.rn (whisper.cpp),
@pocketpalai/react-native-speech, @pocketpalai/react-native-speech-phonon,
onnxruntime-react-native, @fugood/react-native-audio-pcm-stream.

Models are downloaded by the user at first run and are not bundled in the app:

| Asset | Source | License |
|---|---|---|
| Qwen3.5 2B Q4_K_M (initial test candidate); 4B alternative | Qwen/Qwen3.5-2B and Qwen/Qwen3.5-4B; unsloth GGUF conversions | Apache-2.0 |
| Whisper base q8_0 (selected), small alternative | ggerganov/whisper.cpp | MIT |
| Kokoro-82M weights and voices | hexgrad/Kokoro-82M, onnx-community/Kokoro-82M-v1.0-ONNX | Apache-2.0 |
| English phonemizer dictionary | palshub/phonemizer-dicts | CC0-1.0 |

Primary sources checked 2026-11-25:

- [Qwen 2B LICENSE](https://huggingface.co/Qwen/Qwen3.5-2B/blob/15852e8c16360a2fea060d615a32b45270f8a8fc/LICENSE)
  and [4B LICENSE](https://huggingface.co/Qwen/Qwen3.5-4B/blob/851bf6e806efd8d0a36b00ddf55e13ccb7b8cd0a/LICENSE).
- [Unsloth 2B conversion card](https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/blob/f6d5376be1edb4d416d56da11e5397a961aca8ae/README.md)
  declares Apache-2.0 and points to Qwen's license.
- [Kokoro author card](https://huggingface.co/hexgrad/Kokoro-82M)
  and [ONNX conversion card](https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/blob/1939ad2a8e416c0acfeecc08a694d14ef25f2231/README.md)
  declare Apache-2.0; [author voice catalog](https://huggingface.co/hexgrad/Kokoro-82M/blob/f3ff3571791e39611d31c381e3a41a3af07b4987/VOICES.md)
  includes `af_heart`. These repositories returned 404 for a standalone `LICENSE`
  file at those revisions; the evidence is their explicit model-card declaration,
  not an invented license file or a guarantee of voice-personality rights.
- [Whisper model card](https://huggingface.co/ggerganov/whisper.cpp/blob/5359861c739e955e79d9a303bcbc70fb988958b1/README.md)
  declares MIT. Retain the engine's MIT license and applicable model notices.
- [Dictionary provenance/card](https://huggingface.co/datasets/palshub/phonemizer-dicts/blob/2fde2c7911b0b2f950b208edc34331dd1fc70cf9/README.md)
  declares CC0-1.0 and says this is generated output, not redistributed espeak-ng
  source. That assertion is the publisher's evidence, not an independent legal opinion.

Keep all upstream and dependency copyright/license notices when distributing.
Apache redistribution requires a copy of the license, attribution, preserved
applicable notices, and marking modifications. MIT notices must accompany copies.
This notice is not a complete audit of every transitive dependency, OS voice,
trademark or training-data right. No custom voice cloning is authorized by it.
The voice lab is not an official PocketPal or Qwen product.
