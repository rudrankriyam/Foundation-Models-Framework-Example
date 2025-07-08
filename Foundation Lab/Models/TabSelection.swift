//
//  TabSelection.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import Foundation

enum TabSelection: String, CaseIterable, Hashable {
  case examples = "Examples"
  case schemas = "Schemas"
  case tools = "Tools"
  case chat = "Chat"
  case settings = "Settings"
}
