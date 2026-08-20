import Foundation
import PerchCore

@main
struct PerchCLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        do {
            try await run(args)
        } catch {
            fputs("perch: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }

    private static func run(_ args: [String]) async throws {
        switch args.first {
        case nil, "help", "-h", "--help":
            print(usage)
        case "version", "-v", "--version":
            print("perch 1.0.1")
        case "path":
            print(PerchPaths.resolve().home.path)
        case "scan":
            try scan()
        case "status":
            try status()
        case "reclaim":
            let dryRun = args.contains("--dry-run")
            try reclaim(dryRun: dryRun)
        case "delete":
            guard args.contains("--yes") else {
                throw CLIError.message("usage: perch delete <sha256> --yes")
            }
            guard let token = args.dropFirst().first(where: { !$0.hasPrefix("-") }) else {
                throw CLIError.message("usage: perch delete <sha256> --yes")
            }
            try delete(token)
        case "resolve":
            guard let token = args.dropFirst().first else {
                throw CLIError.message("usage: perch resolve <fingerprint>")
            }
            try resolve(token)
        default:
            throw CLIError.message("unknown command \(args[0])\n\n\(usage)")
        }
    }

    private static func session() throws -> PerchSession {
        try PerchSession()
    }

    private static func scan() throws {
        let session = try session()
        let report = try session.scan { progress in
            fputs("\(progress.detail)\n", stderr)
        }
        printReport(report, plan: session.plan(from: report))
    }

    private static func status() throws {
        let session = try session()
        let report = try session.scan()
        printReport(report, plan: session.plan(from: report))
        print("store: \(session.paths.storeRoot.path)")
        print("full-disk-access: \(FullDiskAccess.isGranted() ? "yes" : "no")")
    }

    private static func reclaim(dryRun: Bool) throws {
        let session = try session()
        let report = try session.scan()
        let plan = session.plan(from: report)
        if plan.isEmpty {
            print("Nothing to reclaim or fill. \(report.uniquePackageCount) unique packages already stored once.")
            return
        }
        print("Would reclaim \(ByteFormatting.string(plan.reclaimableBytes)) across \(plan.replacements.count) copies.")
        if !plan.pushes.isEmpty {
            print("Would fill \(plan.pushes.count) missing app folders.")
        }
        if dryRun {
            for item in plan.replacements {
                print("  clone → \(item.destination.path)")
            }
            for item in plan.pushes {
                print("  fill  → \(item.destination.path)")
            }
            return
        }
        let result = try session.reclaim(plan)
        print("Cloned \(result.cloned), copied \(result.copied), filled \(result.pushed), reclaimed \(ByteFormatting.string(result.reclaimedBytes)).")
        for failure in result.failed {
            fputs("  warning: \(failure)\n", stderr)
        }
    }

    private static func delete(_ token: String) throws {
        guard let fingerprint = Fingerprint(rawValue: token) else {
            throw CLIError.message("not a SHA-256 fingerprint")
        }
        let session = try session()
        let report = try session.scan()
        let plan = session.removalPlan(for: fingerprint, report: report)
        if plan.roots.isEmpty {
            throw CLIError.message("nothing to delete")
        }
        try session.remove(plan)
        print("deleted \(plan.roots.count) locations, \(ByteFormatting.string(plan.logicalBytes))")
    }

    private static func resolve(_ token: String) throws {
        let session = try session()
        guard let url = session.resolve(name: token) else {
            throw CLIError.message("not in store: \(token)")
        }
        print(url.path)
    }

    private static func printReport(_ report: ScanReport, plan: ReclaimPlan) {
        print("packages: \(report.placements.count) copies, \(report.uniquePackageCount) unique")
        print("logical:  \(ByteFormatting.string(report.totalLogicalBytes))")
        print("reclaimable: \(ByteFormatting.string(plan.reclaimableBytes))")
        print("fill: \(plan.pushes.count) missing copies")
        for (fingerprint, group) in report.groups.sorted(by: { $0.value[0].displayName < $1.value[0].displayName }) {
            let name = group[0].displayName
            let apps = group.map(\.source.displayName).joined(separator: ", ")
            print("  \(name)  \(ByteFormatting.string(group[0].logicalBytes))  ×\(group.count)  \(fingerprint.rawValue.prefix(12))  [\(apps)]")
        }
    }

    private static let usage = """
        perch — shared store for local speech models

        Usage:
          perch status              Scan and show reclaimable space
          perch scan                Same as status, with progress on stderr
          perch reclaim             Clone duplicates and fill apps that are missing a model
          perch reclaim --dry-run   Show the plan only
          perch delete <sha256> --yes  Remove a model from apps and the store
          perch resolve <name|sha256>  Print the canonical package path
          perch path                Print PERCH_HOME
          perch help
        """
}

enum CLIError: Error, LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self {
        case .message(let text): text
        }
    }
}
