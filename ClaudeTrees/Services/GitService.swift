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

    nonisolated func removeWorktree(repoPath: String, worktreePath: String) async throws {
        _ = try await run("git", args: ["-C", repoPath, "worktree", "remove", worktreePath])
    }

    nonisolated func listBranches(repoPath: String) async throws -> [String] {
        let output = try await run("git", args: ["-C", repoPath, "branch", "--format=%(refname:short)"])
        return output
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
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
