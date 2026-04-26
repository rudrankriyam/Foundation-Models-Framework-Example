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
        case .home:
            return "house.fill"
        case .session:
            return "bubble.left.and.bubble.right.fill"
        case .studio:
            return "slider.horizontal.3"
        case .insights:
            return "sparkle.magnifyingglass"
        }
    }

#if os(macOS)
    var keyboardShortcut: KeyEquivalent {
        switch self {
        case .home: return "1"
        case .session: return "2"
        case .studio: return "3"
        case .insights: return "4"
        }
    }
#endif
}

#Preview {
    NavigationSplitView {
        SidebarView(selection: .constant(.home))
    } detail: {
        Text("Detail View")
    }
}
