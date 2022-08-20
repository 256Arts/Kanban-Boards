//
//  CloudController.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-03.
//

import Foundation

class CloudController: ObservableObject {

    enum FetchError: Error {
        case noObjectForKey
    }

    static let shared = CloudController()

    let iCloudBoardsDirectoryURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let cachedBoardsDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    let metadataQuery = NSMetadataQuery()
    let documentsQuery = NSMetadataQuery()

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidFinishGathering),
            name: Notification.Name.NSMetadataQueryDidFinishGathering,
            object: metadataQuery)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(documentQueryDidUpdate),
            name: NSNotification.Name.NSMetadataQueryDidUpdate,
            object: documentsQuery)
        
        metadataQuery.notificationBatchingInterval = 1
        metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        metadataQuery.start()
        
        documentsQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        documentsQuery.valueListAttributes = [NSMetadataUbiquitousItemPercentDownloadedKey, NSMetadataUbiquitousItemDownloadingStatusKey]
        documentsQuery.start()
    }

    @objc func metadataQueryDidFinishGathering(_ notification: Notification) {
        metadataQuery.disableUpdates()
        Task {
            if !metadataQuery.results.isEmpty {
                do {
                    BoardsController.shared.iCloudBoards = try await fetchICloudBoards()
                } catch {
                    print("Failed to fetch data after query gather")
                }
            }
            metadataQuery.enableUpdates()
        }
    }
    
    @objc func documentQueryDidUpdate(_ notification: Notification) {
        documentsQuery.disableUpdates()
        Task {
            if !documentsQuery.results.isEmpty {
                do {
                    BoardsController.shared.iCloudBoards = try await fetchICloudBoards()
                } catch {
                    print("Failed to fetch data after query gather")
                }
            }
            documentsQuery.enableUpdates()
        }
    }

    func fetchICloudBoards() async throws -> [Board] {
        try FileManager.default.startDownloadingUbiquitousItem(at: iCloudBoardsDirectoryURL)

        let attributes = try iCloudBoardsDirectoryURL.resourceValues(forKeys: [URLResourceKey.ubiquitousItemDownloadingStatusKey])
        if let status: URLUbiquitousItemDownloadingStatus = attributes.allValues[URLResourceKey.ubiquitousItemDownloadingStatusKey] as? URLUbiquitousItemDownloadingStatus {
            switch status {
            case .current, .downloaded:
                return try loadICloudBoards()
            default:
                // Download again
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec
                return try await fetchICloudBoards()
            }
        } else {
            return try loadCachedBoards()
        }
    }

    func loadICloudBoards() throws -> [Board] {
        let boardURLs = try FileManager.default.contentsOfDirectory(at: iCloudBoardsDirectoryURL, includingPropertiesForKeys: nil).filter({ $0.pathExtension == "json" })
        return boardURLs.compactMap {
            print("loading from iCloud URL:", $0)
            return try? JSONDecoder().decode(Board.self, from: Data(contentsOf: $0))
        }
    }

    func loadCachedBoards() throws -> [Board] {
        let boardURLs = try FileManager.default.contentsOfDirectory(at: cachedBoardsDirectoryURL, includingPropertiesForKeys: nil).filter({ $0.pathExtension == "json" })
        return boardURLs.compactMap {
            print("loading from cached URL:", $0)
            return try? JSONDecoder().decode(Board.self, from: Data(contentsOf: $0))
        }
    }
    
    func createICloudBoard(title: String) throws {
        let url = iCloudBoardsDirectoryURL.appendingPathComponent(title, isDirectory: false).appendingPathExtension("json")
        print("icloud new", url)
        let newBoard = Board(modifiedDate: .now, fileURL: url, title: title, columns: [], items: [])
        BoardsController.shared.iCloudBoards.append(newBoard)
        try newBoard.save()
    }

}
