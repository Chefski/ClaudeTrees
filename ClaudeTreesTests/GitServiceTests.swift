//
//  GitServiceTests.swift
//  ClaudeTreesTests
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import Testing
import Foundation
@testable import ClaudeTrees

struct GitServiceTests {

    private let gitService = GitService()

    /// Creates a temporary git repo for testing and returns its path.
    /// Caller is responsible for cleanup.
    private func createTempRepo() async throws -> String {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("claudetrees-test-\(UUID().uuidString)")
        let path = tmp.path(percentEncoded: false)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

        // Initialize a git repo with an initial commit
        let commands = [
            "git init",
            "git config user.email 'test@test.com'",
            "git config user.name 'Test'",
            "touch README.md",
            "git add .",
            "git commit -m 'init'"
        ]
        for cmd in commands {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", cmd]
            process.currentDirectoryURL = tmp
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            try process.run()
            process.waitUntilExit()
        }
        return path
    }

    @Test func listWorktreesReturnsMainWorktree() async throws {
        let repoPath = try await createTempRepo()
        defer { try? FileManager.default.removeItem(atPath: repoPath) }

        let trees = try await gitService.listWorktrees(repoPath: repoPath)
        #expect(!trees.isEmpty)
        #expect(trees.first?.path == repoPath)
        #expect(trees.first?.branch != nil)
    }

    @Test func invalidRepoPathThrows() async throws {
        do {
            _ = try await gitService.listWorktrees(repoPath: "/nonexistent/path")
            #expect(Bool(false), "Expected an error")
        } catch {
            #expect(error is GitError)
        }
    }
}
