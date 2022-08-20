//
//  ItemsColumnView.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-02.
//

import SwiftUI
import NotionSwift
import JaydenCodeGenerator

struct ItemsColumnView: View {

    let column: Column
    let showColumnTitles: Bool
    
    @AppStorage(UserDefaults.Key.showColumnColors) private var showColumnColors = true

    @ObservedObject var board: Board

    @State var newItemTitle = ""
    @State var errorTitle = ""
    @State var showingJaydenCode = false
    
    var jaydenCode: String {
        JaydenCodeGenerator.generateCode(secret: "BAUKU60LCQ")
    }

    var body: some View {
        List {
            Section {
                ForEach(board.items.filter{ $0.column?.notionID == column.notionID }) { item in
                    ItemRowView(board: board, item: item, errorTitle: $errorTitle, showingJaydenCode: $showingJaydenCode)
                }
                TextField("New", text: $newItemTitle) {
                    guard !newItemTitle.isEmpty else { return }

                    Task {
                        do {
                            try await board.createItem(title: newItemTitle, column: column)
                            newItemTitle = ""
                        } catch {
                            print(error)
                            errorTitle = "Failed to Create Item"
                        }
                    }
                }
                .submitLabel(.done)
                .dropDestination(for: Item.self) { items, _ in
                    Task {
                        do {
                            try await withThrowingTaskGroup(of: Void.self, body: { group in
                                for item in items {
                                    item.column = column
                                    group.addTask {
                                        try await item.updateProperties()
                                    }
                                }
                                try await group.waitForAll()
                            })
                            
                            board.objectWillChange.send()
//                            return true
                        } catch {
                            print(error)
                            errorTitle = "Failed to Update Item"
//                            return false
                        }
                    }
                    return true
                }
            } header: {
                showColumnTitles ?
                HStack {
                    Text(column.name)
                        .foregroundColor(showColumnColors ? column.color : nil)
                    Spacer()
                    Menu {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    try await board.deleteColumn(column)
                                } catch {
                                    errorTitle = "Failed to Delete Column"
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                } :
                nil
            }
            .headerProminence(.increased)
        }
        #if targetEnvironment(macCatalyst)
        .frame(minWidth: 260, idealWidth: 300)
        #else
        .frame(minWidth: 300, idealWidth: 340)
        #endif
        .tag(column)
        .alert(errorTitle, isPresented: Binding(get: {
            !errorTitle.isEmpty
        }, set: { newValue in
            errorTitle = newValue ? " " : ""
        })) {
            Button("OK", action: { })
        }
        .alert("Secret Code: \(jaydenCode)", isPresented: $showingJaydenCode) {
            Button("Copy") {
                #if os(macOS)
                let pasteboard = NSPasteboard.general
                pasteboard.declareTypes([.string], owner: nil)
                pasteboard.setString(jaydenCode, forType: .string)
                #else
                UIPasteboard.general.string = jaydenCode
                #endif
            }
            Button("OK", role: .cancel, action: { })
        }
    }
}

struct ItemsColumnView_Previews: PreviewProvider {
    static var previews: some View {
        ItemsColumnView(column: .init(notionID: "", name: "Column", colorName: nil), showColumnTitles: true, board: .debugPreviewBoard)
    }
}
