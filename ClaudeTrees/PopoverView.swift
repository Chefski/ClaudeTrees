//
//  PopoverView.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import SwiftUI

struct PopoverView: View {
    enum Tab: String, CaseIterable {
        case mcps = "MCPs"
        case worktrees = "Worktrees"
    }

    @State private var selectedTab: Tab = .mcps

    var body: some View {
        VStack {
            Picker("Tab", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch selectedTab {
            case .mcps:
                Text("MCPs content")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .worktrees:
                Text("Worktrees content")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .frame(width: 320, height: 400)
    }
}
