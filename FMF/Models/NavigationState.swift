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
}