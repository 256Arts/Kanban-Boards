//
//  Column.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-03.
//

import SwiftUI
import NotionSwift

struct Column: Hashable, Identifiable, Codable {
    
    enum NotionColor: String, Identifiable, CaseIterable, Codable {
        case `default`, brown, orange, yellow, green, blue, purple, pink, red
        
        var id: Self { self }
        var color: Color {
            switch self {
            case .default:
                return .gray
            case .brown:
                return .brown
            case .orange:
                return .orange
            case .yellow:
                return .yellow
            case .green:
                return .green
            case .blue:
                return .blue
            case .purple:
                return .purple
            case .pink:
                return .pink
            case .red:
                return .red
            }
        }
    }
    
    let notionID: UUIDv4?
    var id: UUIDv4 { notionID ?? name }
    let name: String
    
    private let colorName: NotionColor?
    var color: Color {
        colorName?.color ?? .gray
    }
    
    var databaseSelect: DatabasePropertyType.SelectOption? {
        guard let notionID = notionID else { return nil }

        return .init(name: name, id: .init(notionID), color: (colorName ?? .default).rawValue)
    }
    var pageSelect: PagePropertyType.SelectPropertyValue? {
        guard let notionID = notionID else { return nil }
        
        return .init(id: .init(notionID), name: name, color: (colorName ?? .default).rawValue)
    }
    
    init(notionID: UUIDv4?, name: String, colorName: NotionColor?) {
        self.notionID = notionID
        self.name = name
        self.colorName = colorName
    }
    
}
