//
//  BoardView.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-01.
//

import Combine
import SwiftUI
import NotionSwift

struct BoardView: View {
    
    @ObservedObject var notionController: NotionController = .shared
    @ObservedObject var board: Board

    @State var subscriber: AnyCancellable?
    
    @State var selectedColumn: Column
    @State var showingCreateColumn = false

    init(board: Board) {
        self.board = board
        self.selectedColumn = board.columns.first ?? .init(notionID: "", name: "", colorName: nil)
    }
    
    #if os(macOS)
    let statusesTabBarTint = NSColor.secondaryLabelColor
    #else
    let statusesTabBarTint = UIColor.secondaryLabel
    #endif
    
    var body: some View {
        if board.itemsLoaded {
            GeometryReader { geometry in
                if geometry.size.width < 500 {
                    TabView(selection: $selectedColumn) {
                        ForEach(board.columns) { column in
                            ItemsColumnView(column: column, showColumnTitles: false, board: board)
                        }
                    }
                    #if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    #endif
                    .ignoresSafeArea(.container, edges: .bottom)
                    .safeAreaInset(edge: .top) {
                        ColumnsTabBar(board: board, selectedColumn: $selectedColumn)
                            .tint(Color(statusesTabBarTint))
                    }
                    #if os(iOS)
                    .background(Color(UIColor.systemGroupedBackground), ignoresSafeAreaEdges: .all)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .navigationTitle(board.title)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            if let url = board.webURL {
                                Link(destination: url) {
                                    Label("View on Web", systemImage: "safari")
                                }
                            }
                        }
                    }
                } else {
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: -16) {
                            ForEach(board.columns) { column in
                                ItemsColumnView(column: column, showColumnTitles: true, board: board)
                            }
                        }
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                    #if os(iOS)
                    .background(Color(UIColor.systemGroupedBackground), ignoresSafeAreaEdges: .all)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .navigationTitle(board.title)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                if let url = board.webURL {
                                    Link(destination: url) {
                                        Label("View on Web", systemImage: "safari")
                                    }
                                }
                                Button {
                                    showingCreateColumn = true
                                } label: {
                                    Label("Add Column", systemImage: "plus.rectangle.portrait")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                    .sheet(isPresented: $showingCreateColumn) {
                        CreateColumnView(board: board)
                    }
                }
            }
            .menuStyle(.borderlessButton)
        } else {
            ProgressView()
                .frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity)
                #if os(iOS)
                .background(Color(UIColor.systemGroupedBackground), ignoresSafeAreaEdges: .all)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .navigationTitle(board.title)
                .task(priority: .high) {
                    do {
                        try await board.fetchItems()
                        let descriptionFetchPublishers = board.items.compactMap { $0.fetchDescription() }

                        self.subscriber = Publishers.MergeMany(descriptionFetchPublishers)
                            .collect()
                            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                                do {
                                    board.objectWillChange.send()
                                    try board.save()
                                } catch { }
                            })
                    } catch { }
                }
        }
    }
}

struct BoardView_Previews: PreviewProvider {
    static var previews: some View {
        BoardView(board: .debugPreviewBoard)
    }
}
