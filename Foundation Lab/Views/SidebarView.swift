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
                sidebarItem(for: tab)
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Foundation Models")
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
#endif
    }
    
    @ViewBuilder
    private func sidebarItem(for tab: TabSelection) -> some View {
        Label(tab.rawValue, systemImage: tab.systemImage)
            .tag(tab)
#if os(macOS)
            .keyboardShortcut(tab)
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

#if os(macOS)
extension View {
    func keyboardShortcut(_ tab: TabSelection) -> some View {
        if let shortcut = tab.keyboardShortcut {
            return AnyView(self.keyboardShortcut(shortcut, modifiers: .command))
        } else {
            return AnyView(self)
        }
    }
}
#endif

#Preview {
    NavigationSplitView {
        SidebarView(selection: .constant(.examples))
    } detail: {
        Text("Detail View")
    }
}