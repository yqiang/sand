import Foundation
import Testing
@testable import sand

struct HostStoragePreflightTests {
    private func withImage(_ body: (URL) throws -> Void) throws {
        let image = try writeTempFile(contents: "test image")
        defer { try? FileManager.default.removeItem(at: image.deletingLastPathComponent()) }
        try body(image)
    }

    @Test func omittedPolicyDoesNotRestrictTartSources() throws {
        let policy = HostStoragePreflight(availableBytes: { _ in
            Issue.record("Capacity must not be queried when policy is omitted")
            return 0
        })
        try policy.validate(additionalDisks: ["nbd://localhost:10809/cache:ro"], minimumFreeBytes: nil)
    }

    @Test func checksStoreAndDiskFilesystemsAndAcceptsEquality() throws {
        try withImage { image in
            var checked: [String] = []
            let policy = HostStoragePreflight(availableBytes: { path in checked.append(path); return 100 })
            try policy.validate(additionalDisks: [image.path], minimumFreeBytes: 100, tartHome: "/store")
            #expect(checked == ["/store", image.path])
        }
    }

    @Test(arguments: [true, false])
    func eitherFilesystemBelowMinimumFails(storeIsLow: Bool) throws {
        try withImage { image in
            let policy = HostStoragePreflight(availableBytes: { path in
                (path == "/store") == storeIsLow ? 99 : 100
            })
            #expect(throws: HostStoragePreflight.Failure.self) {
                try policy.validate(additionalDisks: [image.path], minimumFreeBytes: 100, tartHome: "/store")
            }
        }
    }

    @Test func rechecksCapacityOnEveryAttempt() throws {
        var free: UInt64 = 100
        let policy = HostStoragePreflight(availableBytes: { _ in free })
        try policy.validate(additionalDisks: [], minimumFreeBytes: 100, tartHome: "/store")
        free = 99
        #expect(throws: HostStoragePreflight.Failure.self) {
            try policy.validate(additionalDisks: [], minimumFreeBytes: 100, tartHome: "/store")
        }
    }

    @Test func directorySymlinkAndMissingImageFailClosed() throws {
        try withImage { image in
            let link = image.deletingLastPathComponent().appendingPathComponent("link")
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: image)
            let policy = HostStoragePreflight(availableBytes: { _ in 100 })
            for path in [image.deletingLastPathComponent().path, link.path, image.path + "-missing"] {
                #expect(throws: (any Error).self) {
                    try policy.validate(additionalDisks: [path], minimumFreeBytes: 1, tartHome: "/store")
                }
            }
        }
    }

    @Test func unreadableFilesystemFailsClosed() {
        let policy = HostStoragePreflight(availableBytes: { _ in throw CocoaError(.fileReadNoPermission) })
        #expect(throws: CocoaError.self) {
            try policy.validate(additionalDisks: [], minimumFreeBytes: 1, tartHome: "/store")
        }
    }

    @Test func configuredReserveSurvivesDecodingAndExpansion() throws {
        let file = try writeTempFile(contents: """
        runners:
          - name: example
            vm:
              source: {type: local, name: base}
              minimumHostFreeBytes: 21474836480
            provisioner:
              type: script
              config: {run: 'true'}
        """)
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        #expect(try Config.load(path: file.path).runners[0].vm.minimumHostFreeBytes == 21474836480)
    }
}
