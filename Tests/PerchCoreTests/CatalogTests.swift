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
        let bundleRoots = [
            "parler": "com.melvynx.parler",
            "handy": "com.pais.handy",
            "meetily": "com.meetily.ai",
        ]
        for (id, bundle) in bundleRoots {
            let app = catalog.apps.first { $0.id == id }
            #expect(app?.roots.contains("~/Library/Application Support/\(bundle)/models") == true)
            #expect(app?.containerRoots.contains("Library/Application Support/\(bundle)/models") == true)
        }
        let dictus = catalog.apps.first { $0.id == "dictus" }
        #expect(dictus?.bundleIds.contains("com.dictus.desktop") == true)
        #expect(dictus?.roots.contains("~/Library/Application Support/com.dictus.desktop/models") == true)
        #expect(dictus?.containerRoots.contains("Library/Application Support/com.dictus.desktop/models") == true)
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
