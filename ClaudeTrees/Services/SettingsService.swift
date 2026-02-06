//
//  SettingsService.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import Foundation

@Observable
final class SettingsService {
    private(set) var servers: [MCPServer] = []
    private(set) var errorMessage: String?

    private var root: [String: Any] = [:]
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL
    }

    static var defaultFileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
    }

    func load() {
        errorMessage = nil
        do {
            let data = try Data(contentsOf: fileURL)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                errorMessage = "settings.json is not a valid JSON object"
                return
            }
            root = json
            servers = Self.parseServers(from: root)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
            errorMessage = "~/.claude/settings.json not found"
            servers = []
            root = [:]
        } catch {
            errorMessage = "Failed to read settings: \(error.localizedDescription)"
            servers = []
            root = [:]
        }
    }

    func setEnabled(_ id: String, _ enabled: Bool) {
        guard var mcpServers = root["mcpServers"] as? [String: Any],
              var entry = mcpServers[id] as? [String: Any] else { return }

        if enabled {
            entry.removeValue(forKey: "disabled")
        } else {
            entry["disabled"] = true
        }
        mcpServers[id] = entry
        root["mcpServers"] = mcpServers

        do {
            let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: fileURL, options: .atomic)
            servers = Self.parseServers(from: root)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save settings: \(error.localizedDescription)"
        }
    }

    private static func parseServers(from root: [String: Any]) -> [MCPServer] {
        guard let mcpServers = root["mcpServers"] as? [String: Any] else { return [] }
        return mcpServers.compactMap { key, value -> MCPServer? in
            guard let dict = value as? [String: Any] else { return nil }
            return MCPServer(
                id: key,
                type: dict["type"] as? String,
                command: dict["command"] as? String,
                args: dict["args"] as? [String],
                env: dict["env"] as? [String: String],
                disabled: dict["disabled"] as? Bool
            )
        }
        .sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
    }
}
