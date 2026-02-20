//
//  GitService.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import Foundation

@Observable
final class GitService {

    nonisolated func listWorktrees(repoPath: String) async throws -> [Worktree] {
        let output = try await run("git", args: ["-C", repoPath, "worktree", "list", "--porcelain"])
        return parseWorktrees(output)
    }

    @discardableResult
    nonisolated func createWorktree(repoPath: String, branchName: String, baseBranch: String?) async throws -> String {
        let worktreePath = worktreePath(repoPath: repoPath, branchName: branchName)
        var args = ["-C", repoPath, "worktree", "add", "-b", branchName, worktreePath]
        if let base = baseBranch {
            args.append(base)
        }
        _ = try await run("git", args: args)
        return worktreePath
    }

    nonisolated func worktreePath(repoPath: String, branchName: String) -> String {
        (repoPath as NSString).deletingLastPathComponent
            .appending("/\(URL(fileURLWithPath: repoPath).lastPathComponent)-\(branchName)")
    }

    nonisolated func removeWorktree(repoPath: String, worktreePath: String, force: Bool = false) async throws {
        var args = ["-C", repoPath, "worktree", "remove"]
        if force { args.append("--force") }
        args.append(worktreePath)
        _ = try await run("git", args: args)
        _ = try await run("git", args: ["-C", repoPath, "worktree", "prune"])
    }

    nonisolated func hasUncommittedChanges(worktreePath: String) async throws -> Bool {
        let output = try await run("git", args: ["-C", worktreePath, "status", "--porcelain"])
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    nonisolated func listBranches(repoPath: String) async throws -> [String] {
        let output = try await run("git", args: ["-C", repoPath, "branch", "--format=%(refname:short)"])
        return output
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    nonisolated func getRemoteURL(worktreePath: String) async throws -> String {
        let output = try await run("git", args: ["-C", worktreePath, "remote", "get-url", "origin"])
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func gitHubBaseURL(from remoteURL: String) -> String? {
        // SSH: git@github.com:owner/repo.git
        if remoteURL.hasPrefix("git@github.com:") {
            var path = String(remoteURL.dropFirst("git@github.com:".count))
            if path.hasSuffix(".git") { path = String(path.dropLast(4)) }
            return "https://github.com/\(path)"
        }
        // HTTPS: https://github.com/owner/repo.git
        if remoteURL.hasPrefix("https://github.com/") {
            var url = remoteURL
            if url.hasSuffix(".git") { url = String(url.dropLast(4)) }
            return url
        }
        return nil
    }

    // MARK: - Private

    nonisolated private func run(_ executable: String, args: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/\(executable)")
            process.arguments = args

            let pipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = pipe
            process.standardError = errorPipe

            process.terminationHandler = { _ in
                if process.terminationStatus != 0 {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown git error"
                    continuation.resume(throwing: GitError.commandFailed(errorString.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: output)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    nonisolated private func parseWorktrees(_ output: String) -> [Worktree] {
        let blocks = output.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return blocks.compactMap { block -> Worktree? in
            let lines = block.components(separatedBy: "\n")
            var path: String?
            var head: String?
            var branch: String?
            var isBare = false

            for line in lines {
                if line.hasPrefix("worktree ") {
                    path = String(line.dropFirst("worktree ".count))
                } else if line.hasPrefix("HEAD ") {
                    let full = String(line.dropFirst("HEAD ".count))
                    head = String(full.prefix(7))
                } else if line.hasPrefix("branch ") {
                    let ref = String(line.dropFirst("branch ".count))
                    branch = ref.replacingOccurrences(of: "refs/heads/", with: "")
                } else if line == "bare" {
                    isBare = true
                }
            }

            guard let p = path, let h = head else { return nil }
            let isMain = isBare || block.contains("branch refs/heads/main") || block.contains("branch refs/heads/master")
            return Worktree(id: p, path: p, branch: branch, head: h, isMain: isMain)
        }
    }
}

enum GitError: LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let msg): return msg
        }
    }
}
