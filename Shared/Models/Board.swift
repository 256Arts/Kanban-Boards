//
//  Board.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-01.
//

import Foundation
import Combine
import NotionSwift

class Board: ObservableObject, Hashable, Identifiable, Codable {

    enum CodingKeys: String, CodingKey {
        case notionID, modifiedDate, webURL, fileURL
        case title, iconURL, columns, items
    }
    
    static func == (lhs: Board, rhs: Board) -> Bool {
        lhs.id == rhs.id
    }
    
    var subscriber: AnyCancellable?
    
    let notionID: Database.Identifier?
    let modifiedDate: Date
    let webURL: URL?
    let fileURL: URL?
    
    @Published var title: String
    @Published var iconURL: URL?
    @Published var columns: [Column]
    @Published var itemsLoaded = false
    @Published var items: [Item] = []
    
    init(modifiedDate: Date, fileURL: URL, title: String, columns: [Column], items: [Item]) {
        self.notionID = nil
        self.modifiedDate = modifiedDate
        self.webURL = nil
        self.fileURL = fileURL
        self.title = title
        self.columns = columns
        self.itemsLoaded = true
        self.items = items
    }
    
    init(database: Database) {
        self.notionID = database.id
        self.modifiedDate = database.lastEditedTime
        self.webURL = URL(string: database.url)!
        self.fileURL = nil
        self.title = database.title.reduce("", { $0 + ($1.plainText ?? "") })
        
        if case .external(let url) = database.icon {
            self.iconURL = URL(string: url)
        } else if case .file(let url, _) = database.icon {
            self.iconURL = URL(string: url)
        } else {
            self.iconURL = nil
        }
        
        if case .select(let select) = database.properties[NotionController.statusPropertyName]?.type {
            self.columns = select.map { .init(notionID: $0.id.rawValue, name: $0.name, colorName: Column.NotionColor(rawValue: $0.color)) }
        } else {
            self.columns = []
        }
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notionID = try? container.decode(Database.Identifier.self, forKey: .notionID)
        modifiedDate = try container.decode(Date.self, forKey: .modifiedDate)
        webURL = try? container.decode(URL.self, forKey: .webURL)
        fileURL = try? container.decode(URL.self, forKey: .fileURL)
        title = try container.decode(String.self, forKey: .title)
        iconURL = try? container.decode(URL.self, forKey: .iconURL)
        columns = try container.decode([Column].self, forKey: .columns)
        itemsLoaded = true
        items = try container.decode([Item].self, forKey: .items)
    }
    
    func fetchItems() async throws {
        guard let notionID = notionID else { return }

        let query = NotionController.shared.notion.databaseQuery(databaseId: notionID)
        
        subscriber = query
            .sink(receiveCompletion: { _ in }, receiveValue: { result in
                self.itemsLoaded = true
                self.items = result.results.map({ Item(page: $0) }).reversed()
                try? self.save()
            })

        _ = try await query.async()
    }

    func createColumn(name: String) async throws {
        if let notionID = notionID {
            guard let database = NotionController.shared.databases.first(where: { $0.id == notionID }) else {
                throw NotionError.unableToFindDatabaseForID
            }
            
            var updatedProperties = database.properties.mapValues({ $0.type })
            let updatedColumns = (columns + [Column(notionID: "", name: name, colorName: nil)]).compactMap { $0.databaseSelect }
            updatedProperties[NotionController.statusPropertyName] = .select(updatedColumns)
            let request = DatabaseUpdateRequest(title: database.title, icon: nil, cover: nil, properties: updatedProperties)
            
            try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
                NotionController.shared.notion.databaseUpdate(databaseId: notionID, request: request) { result in
                    switch result {
                    case .success(let database):
                        if case .select(let select) = database.properties[NotionController.statusPropertyName]?.type {
                            self.columns = select.map { .init(notionID: $0.id.rawValue, name: $0.name, colorName: Column.NotionColor(rawValue: $0.color)) }
                        }
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            })
        } else {
            DispatchQueue.main.async {
                self.columns.append(.init(notionID: nil, name: name, colorName: nil))
                try? self.save()
            }
        }
    }
    
    func deleteColumn(_ column: Column) async throws {
        if let notionID = notionID {
            guard let database = NotionController.shared.databases.first(where: { $0.id == notionID }) else {
                throw NotionError.unableToFindDatabaseForID
            }
            
            var updatedProperties = database.properties.mapValues({ $0.type })
            let updatedColumns = columns.filter { $0.notionID != column.notionID }.compactMap { $0.databaseSelect }
            updatedProperties[NotionController.statusPropertyName] = .select(updatedColumns)
            let request = DatabaseUpdateRequest(title: database.title, icon: nil, cover: nil, properties: updatedProperties)
            
            try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
                NotionController.shared.notion.databaseUpdate(databaseId: notionID, request: request) { result in
                    switch result {
                    case .success(let database):
                        if case .select(let select) = database.properties[NotionController.statusPropertyName]?.type {
                            self.columns = select.map { .init(notionID: $0.id.rawValue, name: $0.name, colorName: Column.NotionColor(rawValue: $0.color)) }
                        }
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            })
        } else {
            DispatchQueue.main.async {
                self.columns.removeAll(where: { $0.id == column.id })
                try? self.save()
            }
        }
    }

    func createItem(title: String, column: Column) async throws {
        if let notionID = notionID {
            let request = PageCreateRequest(parent: .database(notionID), properties: [
                "title": .init(type: .title([ .init(string: title) ])),
                NotionController.statusPropertyName: .init(type: .select( column.pageSelect ))
            ])

            let newPage = try await NotionController.shared.notion.pageCreate(request: request).async()
            DispatchQueue.main.async {
                self.items.append(.init(page: newPage))
            }
        } else {
            DispatchQueue.main.async {
                self.items.append(.init(title: title, column: column))
                try? self.save()
            }
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(notionID, forKey: .notionID)
        try container.encode(modifiedDate, forKey: .modifiedDate)
        try container.encode(webURL, forKey: .webURL)
        try container.encode(fileURL, forKey: .fileURL)
        try container.encode(title, forKey: .title)
        try container.encode(iconURL, forKey: .iconURL)
        try container.encode(columns, forKey: .columns)
        try container.encode(items, forKey: .items)
    }
    
    func save() throws {
        if let fileURL = fileURL {
            try JSONEncoder().encode(self).write(to: fileURL, options: .atomic)
        } else if let notionID = notionID {
            let cacheURL = CloudController.shared.cachedBoardsDirectoryURL.appendingPathComponent(notionID.rawValue, isDirectory: false).appendingPathExtension("json")
            try JSONEncoder().encode(self).write(to: cacheURL, options: .atomic)
        }
    }
    
    static let debugPreviewBoard = Board(database: Database(id: .init(""), url: "", title: [.init(string: "Title")], icon: nil, cover: nil, createdTime: .now, lastEditedTime: .now, createdBy: .init(id: .init("")), lastEditedBy: .init(id: .init("")), properties: [:], parent: .workspace))
    
}
