//
//  BoardsList.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-01.
//

import SwiftUI
import CachedAsyncImage
import NotionSwift

struct BoardsList: View {
    
    @ObservedObject var boardsController: BoardsController = .shared
    
    @State private var selectedBoard: Board?
    @State private var path: [Item] = []
    @State private var showingSettings = false
    @State private var showingCreateBoard = false
    
    #if os(macOS)
    private let boardIconPlaceholderColor = NSColor.controlBackgroundColor
    #else
    private let boardIconPlaceholderColor = UIColor.secondarySystemFill
    #endif
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedBoard) {
                if boardsController.boardsLoaded || !boardsController.boards.isEmpty {
                    ForEach(boardsController.boards) { board in
                        HStack {
                            NavigationLink(value: board) {
                                Label {
                                    Text(board.title)
                                } icon: {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .aspectRatio(1, contentMode: .fill)
                                        .background {
                                            if let url = board.iconURL {
                                                CachedAsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                } placeholder: {
                                                    Color(boardIconPlaceholderColor)
                                                        .overlay {
                                                            ProgressView()
                                                                #if os(macOS)
                                                                .controlSize(.small)
                                                                #endif
                                                        }
                                                }
                                            } else {
                                                Color(boardIconPlaceholderColor)
                                            }
                                        }
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        #if targetEnvironment(macCatalyst)
                                        .padding(2)
                                        #endif
                                }
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .listStyle(.sidebar)
            #if !targetEnvironment(macCatalyst)
            .refreshable {
                boardsController.fetchBoards()
            }
            #endif
            .navigationTitle("Boards")
            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateBoard = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
//                }
            }
        } detail: {
            NavigationStack(path: $path) {
                Group {
                    if let selectedBoard {
                        BoardView(board: selectedBoard)
                    } else {
                        Rectangle()
                            .foregroundColor(Color(UIColor.systemGroupedBackground))
                            .ignoresSafeArea()
                    }
                }
                .navigationDestination(for: Item.self) { item in
                    ItemDetailView(item: item)
                }
            }
        }
        .sheet(isPresented: $showingSettings, content: {
            SettingsView()
        })
        .sheet(isPresented: $showingCreateBoard, content: {
            CreateBoardView(notionController: .shared)
        })
        .task(priority: .high) {
            boardsController.fetchBoards()
        }
    }
}

struct BoardsView_Previews: PreviewProvider {
    static var previews: some View {
        BoardsList()
    }
}
