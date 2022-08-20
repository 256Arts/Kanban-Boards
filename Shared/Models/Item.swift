//
//  Item.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-01.
//

import UniformTypeIdentifiers
import SwiftUI
import Combine
import NotionSwift

class Item: ObservableObject, Hashable, Identifiable, Codable, Transferable {
    
    enum CodingKeys: String, CodingKey {
        case notionID, url, createdDate
        case title, column, description, childItemTitles
    }
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .item)
        ProxyRepresentation(exporting: \.title)
    }
    
    var subscriber: AnyCancellable?
    
    let notionID: Page.Identifier?
    let url: URL?
    let createdDate: Date
    
    @Published var title: String
    @Published var column: Column?
    @Published var description: String
    @Published var childItemTitles: [String]
    
    init(title: String, column: Column?) {
        self.notionID = nil
        self.url = nil
        self.createdDate = .now
        self.title = title
        self.column = column
        self.description = ""
        self.childItemTitles = []
    }
    
    init(page: Page) {
        self.notionID = page.id
        self.createdDate = page.createdTime
        self.title = page.getTitle()?.reduce("", { $0 + ($1.plainText ?? "") }) ?? ""

        if case .url(let url) = page.properties["url"]?.type {
            self.url = url
        } else {
            self.url = nil
        }
        
        if case .select(let select) = page.properties[NotionController.statusPropertyName]?.type, let selectType = select, let id = selectType.id?.rawValue, let name = selectType.name {
            self.column = .init(notionID: id, name: name, colorName: Column.NotionColor(rawValue: selectType.color ?? ""))
        } else {
            self.column = nil
        }

        self.description = ""
        self.childItemTitles = []
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notionID = try? container.decode(Page.Identifier.self, forKey: .notionID)
        url = try? container.decode(URL.self, forKey: .url)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        title = try container.decode(String.self, forKey: .title)
        column = try? container.decode(Column.self, forKey: .column)
        description = try container.decode(String.self, forKey: .description)
        childItemTitles = try container.decode([String].self, forKey: .childItemTitles)
    }
    
    func fetchDescription() -> AnyPublisher<ListResponse<ReadBlock>, NotionClientError>? {
        guard let notionID = notionID else { return nil }

        let query = NotionController.shared.notion.blockChildren(blockId: notionID.toBlockIdentifier)

        subscriber = query
            .sink(receiveCompletion: { _ in }, receiveValue: { result in
                var childItemTitles: [String] = []
                var paragraphs: [String] = []
                
                for block in result.results {
                    switch block.type {
                    case .childPage(let childPage):
                        childItemTitles.append(childPage.title)
                    case .heading1(let heading), .heading2(let heading), .heading3(let heading):
                        paragraphs.append(heading.richText.reduce("", { $0 + ($1.plainText ?? "") }))
                    case .paragraph(let richText):
                        paragraphs.append(richText.richText.reduce("", { $0 + ($1.plainText ?? "") }))
                    default:
                        break
                    }
                }
                
                self.childItemTitles = childItemTitles
                self.description = paragraphs.reduce("", { $0 + $1 + "\n" })
            })

        return query
    }
    
    func updateProperties() async throws {
        guard let notionID = notionID else { return }
        
        let request = PageProperiesUpdateRequest(
            properties: [
                .name("title"): .init(type: .title([ .init(string: title) ])),
                .name(NotionController.statusPropertyName): .init(type: .select(column?.pageSelect))
            ]
        )

        let _ = try await NotionController.shared.notion.pageUpdateProperties(pageId: notionID, request: request).async()
    }
    
    func delete() async throws {
        guard let notionID = notionID else { return }
        
        let _ = try await NotionController.shared.notion.blockDelete(blockId: notionID.toBlockIdentifier, completed: { _ in }).async()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(notionID, forKey: .notionID)
        try container.encode(url, forKey: .url)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(title, forKey: .title)
        try container.encode(column, forKey: .column)
        try container.encode(description, forKey: .description)
        try container.encode(childItemTitles, forKey: .childItemTitles)
    }
    
}

extension UTType {
    static let item = UTType(exportedAs: "com.jaydenirwin.kanbanboards.item")
}
