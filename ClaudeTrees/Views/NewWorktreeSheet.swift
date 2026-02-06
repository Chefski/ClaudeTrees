//
//  NewWorktreeSheet.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import SwiftUI

struct NewWorktreeSheet: View {
    @Environment(GitService.self) private var gitService
    @Environment(AppSettings.self) private var appSettings

    let repo: Repo
    @Binding var isPresented: Bool

    @State private var branchName = ""
    @State private var baseBranch = "main"
    @State private var branches: [String] = []
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .onTapGesture { isPresented = false }

            VStack(spacing: 16) {
                Text("New Worktree")
                    .font(.headline)

                Form {
                    TextField("Branch name:", text: $branchName)
                    Picker("Base branch:", selection: $baseBranch) {
                        ForEach(branches, id: \.self) { branch in
                            Text(branch).tag(branch)
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                HStack {
                    Button("Cancel") { isPresented = false }
                        .keyboardShortcut(.cancelAction)
                    Spacer()
                    Button("Create & Open") { createWorktree() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(branchName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .padding()
            .frame(width: 300)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 8)
        }
        .task {
            do {
                branches = try await gitService.listBranches(repoPath: repo.path)
                if let main = branches.first(where: { $0 == "main" || $0 == "master" }) {
                    baseBranch = main
                } else if let first = branches.first {
                    baseBranch = first
                }
            } catch {
                branches = ["main"]
            }
        }
    }

    private func createWorktree() {
        let name = branchName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isCreating = true
        errorMessage = nil

        Task {
            do {
                let worktreePath = try await gitService.createWorktree(repoPath: repo.path, branchName: name, baseBranch: baseBranch)
                TerminalLauncher.open(
                    path: worktreePath,
                    terminal: appSettings.preferredTerminal,
                    claudeCLIPath: appSettings.claudeCLIPath
                )
                isPresented = false
            } catch {
                errorMessage = error.localizedDescription
                isCreating = false
            }
        }
    }
}
