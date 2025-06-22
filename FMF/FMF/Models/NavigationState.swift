//
//  NavigationState.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/22/25.
//

import SwiftUI

@Observable
class NavigationState {
    var tabSelection: TabSelection = .examples
    var splitViewVisibility: NavigationSplitViewVisibility = .automatic
    
    // For NavigationSplitView selection
    var selectedTab: TabSelection? = .examples
    
    // Synchronize selections between TabView and NavigationSplitView
    func syncSelections() {
        if let selectedTab = selectedTab {
            tabSelection = selectedTab
        } else {
            selectedTab = tabSelection
        }
    }
}