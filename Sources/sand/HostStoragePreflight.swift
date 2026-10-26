import Foundation

// Downstream opt-in policy; the upstream disk-attachment feature stays policy-free.
struct HostStoragePreflight {
    enum Failure: LocalizedError {
        case notRegularImage(String)
        case capacityUnavailable(String)
        case insufficientSpace(path: String, available: UInt64, required: UInt64)

        var errorDescription: String? {
            switch self {
            case .notRegularImage(let path):
                return "Additional disk must be a regular local image file when minimumHostFreeBytes is set: \(path)"
            case .capacityUnavailable(let path):
                return "Cannot determine host free space at \(path)."
            case .insufficientSpace(let path, let available, let required):
                return "Host free space at \(path) is \(available) bytes; require \(required)."
            }
        }
    }

    var availableBytes: (String) throws -> UInt64 = { path in
        let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
        guard let free = attributes[.systemFreeSize] as? NSNumber else {
            throw Failure.capacityUnavailable(path)
        }
        return free.uint64Value
    }

    func validate(
        additionalDisks: [DiskAttachment],
        minimumFreeBytes: UInt64?,
        tartHome: String = ProcessInfo.processInfo.environment["TART_HOME"] ?? "~/.tart"
    ) throws {
        guard let minimumFreeBytes else { return }
        let disks = additionalDisks.map { ($0.source as NSString).expandingTildeInPath }
        // This optional local policy is deliberately stricter than Tart's general
        // attachment syntax: remote sources cannot silently bypass the gate.
        for path in disks {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            guard attributes[.type] as? FileAttributeType == .typeRegular else {
                throw Failure.notRegularImage(path)
            }
        }
        for path in [(tartHome as NSString).expandingTildeInPath] + disks {
            let available = try availableBytes(path)
            guard available >= minimumFreeBytes else {
                throw Failure.insufficientSpace(path: path, available: available, required: minimumFreeBytes)
            }
        }
    }
}
