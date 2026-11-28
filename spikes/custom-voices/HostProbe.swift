import Foundation
#if canImport(Metal)
import Metal
#endif
#if canImport(CoreML)
import CoreML
#endif

// No model download, synthesis, sample capture or consent action occurs here.
// A build host is not an iPhone, even when it has an Apple Silicon processor.
var report: [String: Any] = [
    "schema": 1,
    "scope": "build-host-capability-only",
    "os": ProcessInfo.processInfo.operatingSystemVersionString,
    "physicalMemoryBytes": ProcessInfo.processInfo.physicalMemory,
    "processorCount": ProcessInfo.processInfo.processorCount,
    "modelInferenceExecuted": false,
    "privateAudioRead": false,
    "termsAccepted": false,
]
#if arch(arm64)
report["architecture"] = "arm64"
#else
report["architecture"] = "not-arm64"
#endif
#if canImport(CoreML)
report["coreMLImportAvailable"] = true
#else
report["coreMLImportAvailable"] = false
#endif
#if canImport(Metal)
let devices = MTLCopyAllDevices()
report["metalDeviceNames"] = devices.map { $0.name }
report["metalDefaultDeviceAvailable"] = MTLCreateSystemDefaultDevice() != nil
report["metalDeviceCount"] = devices.count
#else
report["metalDefaultDeviceAvailable"] = false
report["metalDeviceCount"] = 0
report["metalDeviceNames"] = [String]()
#endif
let data = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys, .prettyPrinted])
print(String(decoding: data, as: UTF8.self))
if CommandLine.arguments.count == 2 {
    try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
}
