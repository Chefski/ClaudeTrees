//
//  SettingsServiceTests.swift
//  ClaudeTreesTests
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import Testing
import Foundation
@testable import ClaudeTrees

struct SettingsServiceTests {

    private func tempFileURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    }

    @Test func loadParsesServers() async throws {
        let json: [String: Any] = [
            "env": ["FOO": "bar"],
            "mcpServers": [
                "codex": [
                    "type": "stdio",
                    "command": "codex",
                    "args": ["--arg1"]
                ],
                "other": [
                    "type": "stdio",
                    "command": "other-cmd",
                    "disabled": true
                ]
            ]
        ]
        let url = tempFileURL()
        let data = try JSONSerialization.data(withJSONObject: json)
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let service = SettingsService(fileURL: url)
        service.load()

        #expect(service.servers.count == 2)
        let codex = service.servers.first { $0.id == "codex" }
        #expect(codex?.isEnabled == true)
        #expect(codex?.command == "codex")
        #expect(codex?.args == ["--arg1"])

        let other = service.servers.first { $0.id == "other" }
        #expect(other?.isEnabled == false)
    }

    @Test func togglePreservesUnknownKeys() async throws {
        let json: [String: Any] = [
            "env": ["API_KEY": "secret"],
            "attribution": ["enabled": true],
            "mcpServers": [
                "test-server": [
                    "type": "stdio",
                    "command": "test"
                ]
            ]
        ]
        let url = tempFileURL()
        let data = try JSONSerialization.data(withJSONObject: json)
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let service = SettingsService(fileURL: url)
        service.load()
        service.setEnabled("test-server", false)

        // Re-read and verify unknown keys are preserved
        let reloaded = try Data(contentsOf: url)
        let parsed = try JSONSerialization.jsonObject(with: reloaded) as! [String: Any]

        let env = parsed["env"] as? [String: Any]
        #expect(env?["API_KEY"] as? String == "secret")

        let attribution = parsed["attribution"] as? [String: Any]
        #expect(attribution?["enabled"] as? Bool == true)

        let servers = parsed["mcpServers"] as? [String: Any]
        let testServer = servers?["test-server"] as? [String: Any]
        #expect(testServer?["disabled"] as? Bool == true)
    }

    @Test func toggleEnableRemovesDisabledKey() async throws {
        let json: [String: Any] = [
            "mcpServers": [
                "srv": [
                    "type": "stdio",
                    "command": "srv",
                    "disabled": true
                ]
            ]
        ]
        let url = tempFileURL()
        let data = try JSONSerialization.data(withJSONObject: json)
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let service = SettingsService(fileURL: url)
        service.load()
        #expect(service.servers.first?.isEnabled == false)

        service.setEnabled("srv", true)
        #expect(service.servers.first?.isEnabled == true)

        // Verify disabled key was removed from file
        let reloaded = try Data(contentsOf: url)
        let parsed = try JSONSerialization.jsonObject(with: reloaded) as! [String: Any]
        let servers = parsed["mcpServers"] as? [String: Any]
        let srv = servers?["srv"] as? [String: Any]
        #expect(srv?["disabled"] == nil)
    }

    @Test func loadMissingFileShowsError() async throws {
        let url = tempFileURL() // does not exist
        let service = SettingsService(fileURL: url)
        service.load()

        #expect(service.servers.isEmpty)
        #expect(service.errorMessage != nil)
    }
}
