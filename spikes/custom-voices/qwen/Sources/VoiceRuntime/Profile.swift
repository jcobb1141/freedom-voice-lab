import Foundation
import CryptoKit
import MLX
import MLXAudioTTS

enum SpikeError: Error { case invalid(String) }

struct TensorValues<T: Codable & Sendable>: Codable {
    let shape: [Int]
    let values: [T]

    func validate() throws {
        var size = 1
        guard !shape.isEmpty, shape.count <= 4 else { throw SpikeError.invalid("tensor rank") }
        for dim in shape {
            guard dim > 0, dim <= 100_000, size <= 100_000 / dim else {
                throw SpikeError.invalid("tensor allocation bound")
            }
            size *= dim
        }
        guard size == values.count else { throw SpikeError.invalid("tensor size") }
    }
}

// Engine-specific experimental conditioning, NOT a universal import or an iOS
// encrypted vault. Only this run's deliberately synthetic reference is allowed.
struct SavedProfile: Codable {
    static let revision = "c7755e2504181a771941bb6f9f26ea79b3cdfce3"
    static let modelRevision = "1eccf1cb2519b5a4e8a95b5f0544f3303568164f"
    let schema: Int
    let id: UUID
    let name: String
    let source: String
    let sourceSHA256: String
    let adapterRevision: String
    let baseModelRevision: String
    let language: String
    let codecLanguageID: Int?
    let speaker: TensorValues<Float>?
    let codes: TensorValues<Int32>
    let textTokens: TensorValues<Int32>

    init(_ conditioning: Qwen3TTSModel.Qwen3TTSReferenceConditioning, sourceURL: URL) throws {
        schema = 1
        id = UUID()
        name = "Synthetic native spike voice"
        source = "synthetic-Qwen-VoiceDesign-not-a-human-speaker"
        sourceSHA256 = SHA256.hash(data: try Data(contentsOf: sourceURL))
            .map { String(format: "%02x", $0) }.joined()
        adapterRevision = Self.revision
        baseModelRevision = Self.modelRevision
        language = conditioning.resolvedLanguage
        codecLanguageID = conditioning.codecLanguageID
        speaker = conditioning.speakerEmbedding.map {
            TensorValues(shape: $0.shape, values: $0.asArray(Float.self))
        }
        codes = TensorValues(shape: conditioning.referenceSpeechCodes.shape,
                             values: conditioning.referenceSpeechCodes.asArray(Int32.self))
        textTokens = TensorValues(shape: conditioning.referenceTextTokenIDs.shape,
                                  values: conditioning.referenceTextTokenIDs.asArray(Int32.self))
    }

    func conditioning() throws -> Qwen3TTSModel.Qwen3TTSReferenceConditioning {
        guard schema == 1, adapterRevision == Self.revision,
              baseModelRevision == Self.modelRevision,
              source == "synthetic-Qwen-VoiceDesign-not-a-human-speaker",
              sourceSHA256.count == 64, !language.isEmpty,
              name.count <= 100 else { throw SpikeError.invalid("profile binding") }
        try codes.validate()
        try textTokens.validate()
        if let speaker {
            try speaker.validate()
            guard speaker.values.allSatisfy(\.isFinite) else {
                throw SpikeError.invalid("non-finite embedding")
            }
        }
        return Qwen3TTSModel.Qwen3TTSReferenceConditioning(
            speakerEmbedding: speaker.map { MLXArray($0.values).reshaped($0.shape) },
            referenceSpeechCodes: MLXArray(codes.values).reshaped(codes.shape),
            referenceTextTokenIDs: MLXArray(textTokens.values).reshaped(textTokens.shape),
            resolvedLanguage: language, codecLanguageID: codecLanguageID)
    }

    func save(to url: URL) throws {
        _ = try conditioning()
        try JSONEncoder().encode(self).write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    static func load(from url: URL) throws -> Self {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard ((attributes[.size] as? NSNumber)?.intValue ?? Int.max) <= 5_000_000 else {
            throw SpikeError.invalid("profile file bound")
        }
        let value = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        _ = try value.conditioning()
        return value
    }
}
