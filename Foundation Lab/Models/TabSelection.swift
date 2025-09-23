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
  case languages
  case chat
  case settings
  
  var displayName: String {
    switch self {
    case .integrations:
      return "Integrations"
    case .languages:
      return "Languages"
    default:
      return rawValue.capitalized
    }
  }
}