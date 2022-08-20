//
//  ItemDetailView.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-01.
//

import SwiftUI

struct ItemDetailView: View {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var item: Item

    @State var showingError = false
    
    var body: some View {
        List {
            Section {
                TextField("Title", text: $item.title)
                ZStack {
                    // This invisible Text allows the row to grow to auto height
                    Text(item.description).opacity(0).padding(8)
                    
                    TextEditor(text: $item.description)
                        .background {
                            if item.description.isEmpty {
                                Text("Description")
                                    .foregroundColor(Color(UIColor.placeholderText))
                                    .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                            }
                        }
                }
            } footer: {
                Text("Created \(Self.dateFormatter.string(from: item.createdDate))")
            }
            Section {
                ForEach(item.childItemTitles, id: \.self) { title in
                    Text(title)
                }
            }
            Section {
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await item.delete()
                            dismiss()
                        } catch {
                            print(error)
                            showingError = true
                        }
                    }
                }
            }
        }
        .navigationTitle(item.title)
        .alert("Failed to Delete", isPresented: $showingError) {
            Button("OK", action: { })
        }
    }
}

struct ItemView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailView(item: .init(page: .init(id: .init(""), createdTime: .now, lastEditedTime: .now, createdBy: .init(id: .init("")), lastEditedBy: .init(id: .init("")), icon: nil, cover: nil, parent: .workspace, archived: false, properties: [:])))
    }
}
