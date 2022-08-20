//
//  ItemRowView.swift
//  Kanban Boards (iOS)
//
//  Created by Jayden Irwin on 2022-07-07.
//

import SwiftUI

struct ItemRowView: View {
    
    @ObservedObject var board: Board
    @ObservedObject var item: Item
    @Binding var errorTitle: String
    @Binding var showingJaydenCode: Bool
    
    var body: some View {
        HStack {
            TextField("Title", text: $item.title) {
                if item.title == "This is a secret" {
                    showingJaydenCode = true
                }
                Task { [item] in
                    do {
                        try await item.updateProperties()
                    } catch {
                        print(error)
                        errorTitle = "Failed to Update Item"
                    }
                }
            }
            Spacer()
            NavigationLink(value: item) {
                Image(systemName: item.description.isEmpty ? "note" : "note.text")
            }
            .buttonStyle(.plain)
            .foregroundColor(Color.accentColor)
            .frame(width: 32)
        }
        .draggable(item)
        .contextMenu {
            if let url = item.url {
                Link(destination: url) {
                    Label("View on Web", systemImage: "safari")
                }
            }
            Menu {
                ForEach(board.columns) { newColumn in
                    Button(newColumn.name) {
                        Task { [item] in
                            do {
                                item.column = newColumn
                                try await item.updateProperties()
                                board.objectWillChange.send()
                            } catch {
                                print(error)
                                errorTitle = "Failed to Update Item"
                            }
                        }
                    }
                }
            } label: {
                Label("Move to...", systemImage: "return.right")
            }
            Button(role: .destructive) {
                Task { [item] in
                    do {
                        try await item.delete()
                        board.objectWillChange.send()
                    } catch {
                        print(error)
                        errorTitle = "Failed to Delete Item"
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct ItemRowView_Previews: PreviewProvider {
    static var previews: some View {
        ItemRowView(board: .debugPreviewBoard, item: Item(title: "Item Title", column: nil), errorTitle: .constant(""), showingJaydenCode: .constant(false))
    }
}
