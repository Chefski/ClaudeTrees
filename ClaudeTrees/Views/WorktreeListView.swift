//
//  WorktreeListView.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import SwiftUI

struct WorktreeListView: View {
    @Environment(RepoStore.self) private var repoStore
    @Environment(GitService.self) private var gitService
    @Environment(AppSettings.self) private var appSettings

    @State private var worktreesByRepo: [UUID: [Worktree]] = [:]
    @State private var errorsByRepo: [UUID: String] = [:]
    @State private var loadingRepos: Set<UUID> = []
    @State private var worktreeToDelete: (worktree: Worktree, repo: Repo)?
    @State private var deleteHasChanges = false

    @State private var checkingChanges = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var showDeleteError = false
    @Binding var showNewWorktreeSheet: Bool
    @Binding var newWorktreeRepo: Repo?

    var body: some View {
        Group {
            if repoStore.repos.isEmpty {
                ContentUnavailableView {
                    Label("No Repositories", systemImage: "folder.badge.plus")
                } description: {
                    Text("Add a git repo to manage its worktrees")
                } actions: {
                    Button("Add Repository") { addRepo() }
                }
            } else {
                List {
                    ForEach(repoStore.repos) { repo in
                        Section {
                            if loadingRepos.contains(repo.id) {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 4)
                            } else if let error = errorsByRepo[repo.id] {
                                Label(error, systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            } else if let trees = worktreesByRepo[repo.id], !trees.isEmpty {
                                ForEach(trees) { tree in
                                    WorktreeRow(worktree: tree, onOpen: {
                                        TerminalLauncher.open(
                                            path: tree.path,
                                            terminal: appSettings.preferredTerminal,
                                            claudeCLIPath: appSettings.claudeCLIPath
                                        )
                                    }, onCreatePR: tree.isMain ? nil : {
                                        openCreatePR(for: tree)
                                    }, onDelete: tree.isMain ? nil : {
                                        confirmDelete(worktree: tree, repo: repo)
                                    })
                                }
                            } else {
                                Text("No worktrees")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        } header: {
                            HStack {
                                Image(systemName: "folder")
                                Text(repo.name)
                                Spacer()
                                Button {
                                    newWorktreeRepo = repo
                                    showNewWorktreeSheet = true
                                } label: {
                                    Image(systemName: "plus.circle")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            repoStore.removeRepo(repoStore.repos[index].id)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { addRepo() } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onChange(of: showNewWorktreeSheet) { oldValue, newValue in
            if oldValue && !newValue, let repo = newWorktreeRepo {
                Task { await loadWorktrees(for: repo) }
            }
        }
        .task(id: "loadAll") {
            await loadAllWorktrees()
        }
        .alert("Delete Failed", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteError ?? "")
        }
        .overlay {
            if checkingChanges || isDeleting {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()

                    VStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(isDeleting ? "Deleting..." : "Checking for changes...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                }
            }
        }
    }

    private func addRepo() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a git repository"

        if panel.runModal() == .OK, let url = panel.url {
            repoStore.addRepo(at: url)
            Task { await loadWorktrees(for: repoStore.repos.last!) }
        }
    }

    private func loadAllWorktrees() async {
        for repo in repoStore.repos {
            await loadWorktrees(for: repo)
        }
    }

    private func loadWorktrees(for repo: Repo) async {
        loadingRepos.insert(repo.id)
        errorsByRepo.removeValue(forKey: repo.id)
        defer { loadingRepos.remove(repo.id) }

        guard FileManager.default.fileExists(atPath: repo.path) else {
            errorsByRepo[repo.id] = "Repository not found on disk"
            worktreesByRepo[repo.id] = []
            return
        }

        do {
            let trees = try await gitService.listWorktrees(repoPath: repo.path)
            worktreesByRepo[repo.id] = trees
        } catch {
            errorsByRepo[repo.id] = error.localizedDescription
            worktreesByRepo[repo.id] = []
        }
    }

    private func openCreatePR(for worktree: Worktree) {
        guard let branch = worktree.branch else { return }
        Task {
            guard let remoteURL = try? await gitService.getRemoteURL(worktreePath: worktree.path),
                  let baseURL = GitService.gitHubBaseURL(from: remoteURL),
                  let url = URL(string: "\(baseURL)/compare/\(branch)?expand=1")
            else { return }
            NSWorkspace.shared.open(url)
        }
    }

    private func confirmDelete(worktree: Worktree, repo: Repo) {
        worktreeToDelete = (worktree, repo)
        deleteHasChanges = false
        checkingChanges = true
        Task {
            do {
                deleteHasChanges = try await gitService.hasUncommittedChanges(worktreePath: worktree.path)
            } catch {
                deleteHasChanges = false
            }
            checkingChanges = false

            let alert = NSAlert()
            alert.messageText = deleteHasChanges ? "Uncommitted Changes" : "Remove Worktree?"
            alert.informativeText = deleteHasChanges
                ? "The branch \"\(worktree.branch ?? "")\" has uncommitted changes that will be permanently lost."
                : "This will remove the worktree for \"\(worktree.branch ?? "")\"."
            alert.alertStyle = .warning
            alert.addButton(withTitle: deleteHasChanges ? "Delete Anyway" : "Delete")
            alert.addButton(withTitle: "Cancel")
            alert.buttons.first?.hasDestructiveAction = true

            guard alert.runModal() == .alertFirstButtonReturn else { return }

            isDeleting = true
            await deleteWorktree(worktree, from: repo, force: deleteHasChanges)
            isDeleting = false
        }
    }

    private func deleteWorktree(_ worktree: Worktree, from repo: Repo, force: Bool) async {
        do {
            try await gitService.removeWorktree(repoPath: repo.path, worktreePath: worktree.path, force: force)
            worktreeToDelete = nil
            await loadWorktrees(for: repo)
        } catch {
            worktreeToDelete = nil
            deleteError = error.localizedDescription
            showDeleteError = true
        }
    }
}
