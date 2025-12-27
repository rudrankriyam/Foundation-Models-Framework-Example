//
//  Array+BulletList.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/20/25.
//

extension Array where Element == String {
    func bulletList(prefix: String = "• ") -> String {
        map { "\(prefix)\($0)" }.joined(separator: "\n")
    }
}
