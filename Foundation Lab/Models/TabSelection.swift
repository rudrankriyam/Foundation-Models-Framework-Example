//
//  TabSelection.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import Foundation

enum TabSelection: String, CaseIterable, Hashable {
  case examples
  case integrations
  case voice
  case settings

  var displayName: String {
    switch self {
    case .integrations:
      return "Integrations"
    default:
      return rawValue.capitalized
    }
  }
}
