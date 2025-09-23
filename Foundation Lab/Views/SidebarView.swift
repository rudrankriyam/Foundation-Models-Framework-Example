//
//  SidebarView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/22/25.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: TabSelection?
    
    var body: some View {
        List(selection: $selection) {
            ForEach(TabSelection.allCases, id: \.self) { tab in
                Label(tab.displayName, systemImage: tab.systemImage)
                    .tag(tab)
#if os(macOS)
                    .keyboardShortcut(tab.keyboardShortcut, modifiers: .command)
#endif
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Foundation Models")
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
#endif
    }
}

extension TabSelection {
    var systemImage: String {
        switch self {
        case .examples:
            return "sparkles"
        case .schemas:
            return "doc.text"
        case .tools:
            return "wrench.and.screwdriver"
        case .languages:
            return "globe"
        case .chat:
            return "bubble.left.and.bubble.right"
        case .settings:
            return "gear"
        }
    }
    
#if os(macOS)
    var keyboardShortcut: KeyEquivalent {
        switch self {
        case .examples: return "1"
        case .schemas: return "2"
        case .tools: return "3"
        case .languages: return "4"
        case .chat: return "5"
        case .settings: return "6"
        }
    }
#endif
}

#Preview {
    NavigationSplitView {
        SidebarView(selection: .constant(.examples))
    } detail: {
        Text("Detail View")
    }
}