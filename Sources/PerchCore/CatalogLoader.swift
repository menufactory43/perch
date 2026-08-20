import Foundation

public enum CatalogLoader {
    public static func bundled() throws -> Catalog {
        guard let url = Bundle.module.url(forResource: "catalog", withExtension: "json") else {
            throw CatalogError.missingBundle
        }
        return try load(from: url)
    }

    public static func load(from url: URL) throws -> Catalog {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(Catalog.self, from: data)
    }
}

public enum CatalogError: Error, Sendable {
    case missingBundle
}
