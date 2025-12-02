//
//  TabSelection.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import Foundation

enum TabSelection: String, CaseIterable, Hashable {
  case examples
  case tools
  case schemas
  case languages
  case settings

  var displayName: String {
    switch self {
    case .examples:
      return "Examples"
    case .tools:
      return "Tools"
    case .schemas:
      return "Schemas"
    case .languages:
      return "Languages"
    case .settings:
      return "Settings"
    }
  }
}
