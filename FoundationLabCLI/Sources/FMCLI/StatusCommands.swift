import ArgumentParser
import Foundation
import FoundationLabCore

struct StatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show Foundation Models readiness and CLI capability support."
    )

    @OptionGroup var options: CLIOptions

    mutating func run() async throws {
        let availability = CheckModelAvailabilityUseCase().execute()
        let commandGroups = CLIStatusGroup.defaultGroups(for: availability)

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "status"
                ],
                human: "[dry-run] fm status",
                json: options.json
            )
            return
        }

        CLIOutput.emit(
            payload: [
                "foundationModels": foundationModelsPayload(for: availability),
                "commandGroups": commandGroups.map(\.payload),
                "summary": statusSummaryPayload(for: commandGroups)
            ],
            human: humanReadableStatus(
                availability: availability,
                commandGroups: commandGroups,
                verbose: options.verbose
            ),
            json: options.json
        )
    }
}

private struct CLIStatusGroup {
    let id: String
    let title: String
    let status: String
    let reason: String
    let commands: [String]

    var payload: [String: Any] {
        [
            "id": id,
            "title": title,
            "status": status,
            "reason": reason,
            "commands": commands
        ]
    }

    static func defaultGroups(for availability: ModelAvailabilityResult) -> [CLIStatusGroup] {
        let foundationModelsReason = availabilityReasonDescription(for: availability)

        let sharedCoreGroups = [
            CLIStatusGroup(
                id: "book",
                title: "Book Recommendations",
                status: availability.isAvailable ? "available" : "unavailable",
                reason: availability.isAvailable ? "" : foundationModelsReason,
                commands: ["fm book recommend"]
            ),
            CLIStatusGroup(
                id: "nutrition",
                title: "Nutrition Analysis",
                status: availability.isAvailable ? "available" : "unavailable",
                reason: availability.isAvailable ? "" : foundationModelsReason,
                commands: ["fm nutrition analyze"]
            ),
            CLIStatusGroup(
                id: "weather",
                title: "Weather",
                status: availability.isAvailable ? "available" : "unavailable",
                reason: availability.isAvailable ? "" : foundationModelsReason,
                commands: ["fm weather get"]
            ),
            CLIStatusGroup(
                id: "web",
                title: "Web",
                status: availability.isAvailable ? "available" : "unavailable",
                reason: availability.isAvailable ? "" : foundationModelsReason,
                commands: ["fm web search", "fm web summary"]
            ),
            CLIStatusGroup(
                id: "examples",
                title: "Examples",
                status: availability.isAvailable ? "available" : "partially_available",
                reason: availability.isAvailable
                    ? ""
                    : "Most example commands require Apple Intelligence. `fm examples list` still works.",
                commands: [
                    "fm examples list",
                    "fm examples basic-chat"
                ]
            ),
            CLIStatusGroup(
                id: "schemas",
                title: "Schemas",
                status: availability.isAvailable ? "available" : "partially_available",
                reason: availability.isAvailable
                    ? ""
                    : "Schema execution requires Apple Intelligence. `fm schemas list` still works.",
                commands: ["fm schemas list", "fm schemas basic-object"]
            ),
            CLIStatusGroup(
                id: "languages",
                title: "Languages",
                status: availability.isAvailable ? "available" : "partially_available",
                reason: availability.isAvailable
                    ? ""
                    : "Language demos require Apple Intelligence. `fm languages list` still works.",
                commands: ["fm languages list", "fm languages multilingual"]
            ),
            CLIStatusGroup(
                id: "chat",
                title: "Chat",
                status: availability.isAvailable ? "available" : "unavailable",
                reason: availability.isAvailable ? "" : foundationModelsReason,
                commands: ["fm chat run"]
            )
        ]

        let appOnlyReason = "Requires app entitlements and permissions that are not available to standalone CLI execution."
        let appOnlyGroups = [
            CLIStatusGroup(
                id: "contacts",
                title: "Contacts",
                status: "app_only",
                reason: appOnlyReason,
                commands: ["fm contacts search"]
            ),
            CLIStatusGroup(
                id: "calendar",
                title: "Calendar",
                status: "app_only",
                reason: appOnlyReason,
                commands: ["fm calendar query"]
            ),
            CLIStatusGroup(
                id: "reminders",
                title: "Reminders",
                status: "app_only",
                reason: appOnlyReason,
                commands: ["fm reminders request"]
            ),
            CLIStatusGroup(
                id: "location",
                title: "Location",
                status: "app_only",
                reason: appOnlyReason,
                commands: ["fm location current"]
            ),
            CLIStatusGroup(
                id: "music",
                title: "Music",
                status: "app_only",
                reason: appOnlyReason,
                commands: ["fm music search"]
            ),
            CLIStatusGroup(
                id: "health",
                title: "Health",
                status: "app_only",
                reason: appOnlyReason,
                commands: ["fm health query"]
            )
        ]

        return sharedCoreGroups + appOnlyGroups
    }
}

private func foundationModelsPayload(for availability: ModelAvailabilityResult) -> [String: Any] {
    [
        "status": availability.isAvailable ? "available" : "unavailable",
        "isAvailable": availability.isAvailable,
        "reason": availability.reason?.rawValue ?? "",
        "description": availabilityReasonDescription(for: availability),
        "provider": availability.metadata.provider ?? "Foundation Models"
    ]
}

private func statusSummaryPayload(for groups: [CLIStatusGroup]) -> [String: Any] {
    let availableCount = groups.filter { $0.status == "available" }.count
    let partiallyAvailableCount = groups.filter { $0.status == "partially_available" }.count
    let unavailableCount = groups.filter { $0.status == "unavailable" }.count
    let appOnlyCount = groups.filter { $0.status == "app_only" }.count

    return [
        "available": availableCount,
        "partiallyAvailable": partiallyAvailableCount,
        "unavailable": unavailableCount,
        "appOnly": appOnlyCount,
        "total": groups.count
    ]
}

private func humanReadableStatus(
    availability: ModelAvailabilityResult,
    commandGroups: [CLIStatusGroup],
    verbose: Bool
) -> String {
    var lines = [
        "Foundation Models",
        "Status: \(availability.isAvailable ? "Available" : "Unavailable")",
        "Reason: \(availabilityReasonDescription(for: availability))",
        ""
    ]

    let groupedStatuses = [
        ("Available Now", "available"),
        ("Partially Available", "partially_available"),
        ("Unavailable Right Now", "unavailable"),
        ("App-Only", "app_only")
    ]

    for (sectionTitle, status) in groupedStatuses {
        let matches = commandGroups.filter { $0.status == status }
        guard !matches.isEmpty else { continue }

        lines.append(sectionTitle)
        for match in matches {
            if verbose {
                let commands = match.commands.joined(separator: ", ")
                let reasonSuffix = match.reason.isEmpty ? "" : " (\(match.reason))"
                lines.append("- \(match.title): \(commands)\(reasonSuffix)")
            } else if match.reason.isEmpty {
                lines.append("- \(match.title)")
            } else {
                lines.append("- \(match.title): \(match.reason)")
            }
        }
        lines.append("")
    }

    return lines.dropLast().joined(separator: "\n")
}

private func availabilityReasonDescription(for availability: ModelAvailabilityResult) -> String {
    guard !availability.isAvailable else {
        return "Apple Intelligence is available and ready to use."
    }

    switch availability.reason {
    case .deviceNotEligible:
        return "This device is not eligible for Apple Intelligence."
    case .appleIntelligenceNotEnabled:
        return "Apple Intelligence is turned off in Settings."
    case .modelNotReady:
        return "Model assets are still being prepared on this device."
    case .unknown, .none:
        return "Apple Intelligence is unavailable for an unknown reason."
    }
}
