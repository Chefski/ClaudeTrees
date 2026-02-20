//
//  WorktreeRow.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import SwiftUI

struct WorktreeRow: View {
    let worktree: Worktree
    let onOpen: () -> Void
    var onCreatePR: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: worktree.isMain ? "crown" : "arrow.triangle.branch")
                        .font(.caption)
                        .foregroundStyle(worktree.isMain ? .yellow : .secondary)
                    Text(worktree.branch ?? worktree.head)
                        .fontWeight(.medium)
                }
                Text(abbreviatePath(worktree.path))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                NSWorkspace.shared.open(URL(fileURLWithPath: worktree.path))
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.plain)
            .help("Open in Finder")
            Button {
                onOpen()
            } label: {
                Image(systemName: "terminal")
            }
            .buttonStyle(.plain)
            .help("Open in terminal")
            if !worktree.isMain, let onCreatePR {
                Button {
                    onCreatePR()
                } label: {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.plain)
                .help("Create pull request")
            }
            if !worktree.isMain, let onDelete {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Remove worktree")
            }
        }
        .padding(.vertical, 2)
    }

    private func abbreviatePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
