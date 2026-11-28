import Foundation
import MLX
import MLXAudioCore
import MLXAudioTTS

@main
struct VoiceRuntime {
    static let referenceText = "Hello there. This is an entirely synthetic voice for a private local synthesis experiment. No real speaker is being imitated."

    static func metric(_ values: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: values, options: [.sortedKeys])
        print("VOICE_SPIKE_METRIC " + String(decoding: data, as: UTF8.self))
    }

    static func validate(_ audio: MaterializedArray, label: String) throws {
        let samples = audio.asArray(Float.self)
        guard samples.count > 2_400, samples.allSatisfy(\.isFinite),
              samples.contains(where: { abs($0) > 0.0001 }) else {
            throw SpikeError.invalid("empty, silent or invalid output: \(label)")
        }
        try metric(["stage": label, "samples": samples.count,
                    "audioSeconds": Double(samples.count) / 24_000,
                    "evidence": "native-waveform-not-audible-quality"])
    }

    static func main() async throws {
        let args = CommandLine.arguments
        guard args.count == 4, ["design", "clone", "reopen"].contains(args[1]) else {
            throw SpikeError.invalid("usage: VoiceRuntime design|clone|reopen model-directory private-output-directory")
        }
        let stage = args[1]
        let output = URL(fileURLWithPath: args[3], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        let reference = output.appendingPathComponent("synthetic-reference.wav")
        let profileURL = output.appendingPathComponent("conditioning.json")
        let start = Date()
        let model = try await Qwen3TTSModel.fromModelDirectory(URL(fileURLWithPath: args[2]))
        try metric(["stage": stage + "-loaded", "elapsedSeconds": Date().timeIntervalSince(start)])
        let parameters = GenerateParameters(maxTokens: 160, temperature: 0.7, topK: 50)

        if stage == "design" {
            let audio = try await model.generate(
                text: referenceText,
                voice: "An obviously synthetic adult narrator with a calm warm tone, neutral English accent and clear measured delivery.",
                refAudio: nil, refText: nil, language: "English",
                generationParameters: parameters)
            try validate(audio, label: "genuine-VoiceDesign")
            try AudioUtils.writeWavFile(samples: audio.asArray(Float.self), sampleRate: 24_000,
                                        fileURL: reference)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: reference.path)
        } else {
            if stage == "clone" {
                let (_, samples) = try loadAudioArray(from: reference, sampleRate: 24_000)
                let conditioning = try model.prepareReferenceConditioning(
                    refAudio: samples, refText: referenceText, language: "English")
                let profile = try SavedProfile(conditioning, sourceURL: reference)
                try profile.save(to: profileURL)
                // Repeated and next-process generation must use saved conditioning,
                // not silently re-encode the original audio every time.
                try FileManager.default.removeItem(at: reference)
                try metric(["stage": "saved-native-conditioning", "id": profile.id.uuidString,
                            "sourceAudioDeleted": true])
            }
            let profile = try SavedProfile.load(from: profileURL)
            let savedBytes = try Data(contentsOf: profileURL)
            let conditioning = try profile.conditioning()
            for i in 1...(stage == "clone" ? 2 : 1) {
                let text = i == 1 ? "The local voice profile has been reopened successfully."
                                 : "This is a different sentence using the same saved voice."
                let audio = try await model.generate(text: text, conditioning: conditioning,
                                                     generationParameters: parameters)
                try validate(audio, label: stage + "-synthesis-\(i)")
            }
            guard savedBytes == (try Data(contentsOf: profileURL)) else {
                throw SpikeError.invalid("conditioning changed during synthesis")
            }
            if stage == "reopen" {
                let generation = Task {
                    let stream = model.generateStream(
                        text: String(repeating: "A long cancellation test sentence. ", count: 50),
                        conditioning: conditioning,
                        generationParameters: GenerateParameters(maxTokens: 512))
                    for try await _ in stream { try Task.checkCancellation() }
                }
                try await Task.sleep(for: .milliseconds(300))
                let cancelStart = Date()
                generation.cancel()
                do {
                    try await generation.value
                } catch is CancellationError {
                    // Expected cooperative stop, not an inference success.
                }
                let ms = Date().timeIntervalSince(cancelStart) * 1_000
                try metric(["stage": "cancel", "consumerCompletionMs": ms,
                            "withinOneSecond": ms <= 1_000,
                            "nativeProducerJoinObserved": false,
                            "physicalPlaybackFlushTested": false])
                guard ms <= 1_000 else { throw SpikeError.invalid("host cancellation exceeded one second") }
            }
        }
        try metric(["stage": stage + "-done", "elapsedSeconds": Date().timeIntervalSince(start),
                    "deviceAcceptance": false])
    }
}
