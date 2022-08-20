//
//  ColumnsTabBar.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-01.
//

import SwiftUI
import NotionSwift

struct ColumnsTabBar: View {
    
    @AppStorage(UserDefaults.Key.showColumnColors) private var showColumnColors = true
    
    @ObservedObject var board: Board
    
    @Binding var selectedColumn: Column
    
    @State var showingCreateColumn = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(board.columns) { column in
                        if column.id == selectedColumn.id {
                            Button(column.name) {
                                selectedColumn = column
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(showColumnColors ? column.color : nil)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        do {
                                            try await board.deleteColumn(column)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        } else {
                            Button(column.name) {
                                selectedColumn = column
                            }
                            .buttonStyle(.bordered)
                            .tint(showColumnColors ? column.color : nil)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        do {
                                            try await board.deleteColumn(column)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    Button("+") {
                        showingCreateColumn = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .onChange(of: selectedColumn) { newValue in
                proxy.scrollTo(newValue.id)
            }
        }
        .sheet(isPresented: $showingCreateColumn) {
            CreateColumnView(board: board)
        }
    }
}

struct StatusesTabBar_Previews: PreviewProvider {
    static var previews: some View {
        ColumnsTabBar(board: .debugPreviewBoard, selectedColumn: .constant(.init(notionID: "", name: "", colorName: nil)))
    }
}
