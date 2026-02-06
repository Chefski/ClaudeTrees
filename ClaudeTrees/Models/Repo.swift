//
//  Repo.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import Foundation

struct Repo: Identifiable, Codable {
    let id: UUID
    var path: String
    var name: String

    init(id: UUID = UUID(), path: String) {
        self.id = id
        self.path = path
        self.name = URL(fileURLWithPath: path).lastPathComponent
    }
}
