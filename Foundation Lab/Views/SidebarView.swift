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
                Label(tab.rawValue, systemImage: tab.systemImage)
                    .tag(tab)
#if os(macOS)
                    .if(tab.keyboardShortcut != nil) { view in
                        view.keyboardShortcut(tab.keyboardShortcut!, modifiers: .command)
                    }
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
        case .chat:
            return "bubble.left.and.bubble.right"
        case .bodyBuddy:
            return "heart.text.square"
        case .psylean:
            return "sparkles.rectangle.stack"
        case .settings:
            return "gear"
        }
    }
    
#if os(macOS)
    var keyboardShortcut: KeyEquivalent? {
        let allCases = TabSelection.allCases
        guard let index = allCases.firstIndex(of: self),
              index < 9 else { return nil } // Only support 1-9
        return KeyEquivalent(Character(String(index + 1)))
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