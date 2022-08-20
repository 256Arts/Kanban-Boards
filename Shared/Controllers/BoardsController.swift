//
//  BoardsController.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-03.
//

import Foundation

class BoardsController: ObservableObject {
    
    static let shared = BoardsController()

    @Published private var notionBoardsLoaded = false
    @Published private var iCloudBoardsLoaded = false
    var boardsLoaded: Bool {
        notionBoardsLoaded && iCloudBoardsLoaded
    }

    @Published var notionBoards: [Board] = []
    @Published var iCloudBoards: [Board] = []
    var boards: [Board] {
        notionBoards + iCloudBoards
    }
    
    func fetchBoards() {
        Task {
            do {
                let iCloudBoards = try await sort(CloudController.shared.fetchICloudBoards())
                DispatchQueue.main.async {
                    self.iCloudBoards = iCloudBoards
                    self.iCloudBoardsLoaded = true
                }
            } catch { }
        }
        Task {
            DispatchQueue.main.async {
                self.notionBoards = (try? self.sort(CloudController.shared.loadCachedBoards())) ?? []
            }
            do {
                let notionBoards = try await self.sort(NotionController.shared.fetchBoards())
                DispatchQueue.main.async {
                    self.notionBoards = notionBoards
                    self.notionBoardsLoaded = true
                }
                for board in notionBoards {
                    try? board.save()
                }
            } catch { }
        }
    }

    func sort(_ boards: [Board]) -> [Board] {
        boards.sorted(by: { lhs, rhs in
            if let sortRawValue = UserDefaults.standard.string(forKey: UserDefaults.Key.sortBoards), let sort = SettingsView.Sort(rawValue: sortRawValue), sort == .name {
                return lhs.title < rhs.title
            } else {
                return lhs.modifiedDate < rhs.modifiedDate
            }
        })
    }
    
}
