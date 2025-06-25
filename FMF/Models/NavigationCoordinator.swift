//
//  NavigationCoordinator.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/25/25.
//

import SwiftUI
import Observation

@Observable
final class NavigationCoordinator {
    static let shared = NavigationCoordinator()

    var tabSelection: TabSelection = .examples
    var splitViewSelection: TabSelection? = .examples

    private init() {}

    @MainActor
    public func navigate(to tab: TabSelection) {
        tabSelection = tab
        splitViewSelection = tab
    }
}
