import Foundation
import Testing
@testable import PerchCore

struct CatalogTests {
    @Test func bundledCatalogLoads() throws {
        let catalog = try CatalogLoader.bundled()
        #expect(catalog.version >= 4)
        #expect(catalog.apps.contains { $0.id == "fluidaudio" })
        #expect(catalog.apps.contains { $0.id == "huggingface" })
        #expect(catalog.apps.contains { $0.id == "voiceink" })
    }

    @Test func catalogCoversBundleIdModelFolders() throws {
        let catalog = try CatalogLoader.bundled()
        for id in ["parler", "handy", "meetily"] {
            #expect(catalog.apps.contains { $0.id == id })
        }
        let dictus = catalog.apps.first { $0.id == "dictus" }
        #expect(dictus?.bundleIds.contains("com.dictus.desktop") == true)
    }

    @Test func expanderResolvesHome() {
        let home = URL(fileURLWithPath: "/Users/tester")
        let expander = PathExpander(
            home: home,
            containersRoot: home.appending(path: "Library/Containers")
        )
        #expect(expander.expand("~/Library/Application Support/FluidAudio/Models").path.hasPrefix("/Users/tester/Library"))
    }

    @Test func perchHomeOverride() {
        let paths = PerchPaths.resolve(environment: ["PERCH_HOME": "/tmp/custom-perch"])
        #expect(paths.home.path == "/tmp/custom-perch")
        #expect(paths.storeRoot.lastPathComponent == "store")
    }
}
