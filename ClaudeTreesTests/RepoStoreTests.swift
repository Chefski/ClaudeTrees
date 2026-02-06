//
//  RepoStoreTests.swift
//  ClaudeTreesTests
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import Testing
import Foundation
@testable import ClaudeTrees

struct RepoStoreTests {

    private func freshDefaults() -> UserDefaults {
        let name = UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func addAndRemoveRepo() async throws {
        let defaults = freshDefaults()
        let store = RepoStore(defaults: defaults)

        #expect(store.repos.isEmpty)

        let url = URL(fileURLWithPath: "/tmp/test-repo")
        store.addRepo(at: url)
        #expect(store.repos.count == 1)
        #expect(store.repos.first?.path == "/tmp/test-repo")
        #expect(store.repos.first?.name == "test-repo")

        // Adding same repo again should not duplicate
        store.addRepo(at: url)
        #expect(store.repos.count == 1)

        // Remove
        let id = store.repos.first!.id
        store.removeRepo(id)
        #expect(store.repos.isEmpty)
    }

    @Test func persistsAcrossInstances() async throws {
        let defaults = freshDefaults()

        let store1 = RepoStore(defaults: defaults)
        store1.addRepo(at: URL(fileURLWithPath: "/tmp/repo-a"))
        store1.addRepo(at: URL(fileURLWithPath: "/tmp/repo-b"))

        let store2 = RepoStore(defaults: defaults)
        #expect(store2.repos.count == 2)
    }
}
