//
//  TabSelection.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import Foundation

enum TabSelection: String, CaseIterable, Hashable {
  case home
  case session
  case studio
  case insights

  var displayName: String {
    switch self {
    case .home:
      return "Home"
    case .session:
      return "Session"
    case .studio:
      return "Studio"
    case .insights:
      return "Insights"
    }
  }
}
