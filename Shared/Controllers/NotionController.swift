//
//  NotionController.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-01.
//

import NotionSwift
import Foundation

class NotionController: ObservableObject {
    
    static var shared = NotionController(integrationToken: UserDefaults.standard.string(forKey: UserDefaults.Key.notionIntegrationToken) ?? "")
    static let statusPropertyName = "Status"
    
    let integrationToken: String
    let notion: NotionClient
    
    var databases: [Database] = []
    
    init(integrationToken: String) {
        self.integrationToken = integrationToken
        self.notion = NotionClient(accessKeyProvider: StringAccessKeyProvider(accessKey: integrationToken))
    }
    
    func fetchBoards() async throws -> [Board] {
        try await withCheckedThrowingContinuation { continuation in
            notion.search(request: .init(filter: .database)) { result in
                let databases = result.map { objects in
                    objects.results.compactMap({ object -> Database? in
                        if case .database(let db) = object {
                            return db
                        }
                        return nil
                    })
                }

                do {
                    self.databases = try databases.get()
                    continuation.resume(returning: self.databases.map({ Board(database: $0) }))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

//    func createBoard(title: String) async throws {
//        #warning("Creating boards at the root level is not supported by Notion API")
//        let request = DatabaseCreateRequest(parent: .workspace, icon: nil, cover: nil, title: [.init(string: title)], properties: [:])
//
//        try await notion.databaseCreate(request: request).async()
//    }
    
}

enum NotionError: Error {
    case unableToFindDatabaseForID
}

extension NotionClientError {
    var betterDescription: String {
        switch self {
        case .genericError(let error):
            return error.localizedDescription
        case .apiError(_, _, let message):
            return message
        case .bodyEncodingError(let error):
            return error.localizedDescription
        case .decodingError(let error):
            return error.localizedDescription
        case .unsupportedResponseError:
            return "Unsupported Response"
        case .builderError(let message):
            return message
        }
    }
}
