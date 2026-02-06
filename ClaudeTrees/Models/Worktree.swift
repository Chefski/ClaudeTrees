//
//  Worktree.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import Foundation

struct Worktree: Identifiable {
    let id: String
    let path: String
    let branch: String?
    let head: String
    let isMain: Bool
}
