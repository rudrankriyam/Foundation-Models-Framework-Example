//
//  TabSelection.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import Foundation

enum TabSelection: String, CaseIterable, Hashable {
  case examples
  case schemas
  case tools
  case languages
  case chat
  case settings
  
  var displayName: String {
    rawValue.capitalized
  }
}
