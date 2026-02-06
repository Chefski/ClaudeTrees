//
//  RepoStore.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import Foundation

@Observable
final class RepoStore {
    private(set) var repos: [Repo] = []
    private let defaults: UserDefaults
    private let key = "savedRepos"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func addRepo(at url: URL) {
        let path = url.path(percentEncoded: false)
        guard !repos.contains(where: { $0.path == path }) else { return }
        repos.append(Repo(path: path))
        save()
    }

    func removeRepo(_ id: UUID) {
        repos.removeAll { $0.id == id }
        save()
    }

    func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Repo].self, from: data) else { return }
        repos = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(repos) else { return }
        defaults.set(data, forKey: key)
    }
}
