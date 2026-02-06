//
//  MCPServer.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import Foundation

struct MCPServer: Identifiable {
    let id: String
    var type: String?
    var command: String?
    var args: [String]?
    var env: [String: String]?
    var disabled: Bool?

    var isEnabled: Bool { !(disabled ?? false) }
}
