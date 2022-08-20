//
//  CreateBoardView.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-02.
//

import SwiftUI

struct CreateBoardView: View {
    
    enum StorageLocation: String, Identifiable, CaseIterable {
        case iCloud
        case notion = "Notion"
        
        var id: Self { self }
    }

    @Environment(\.dismiss) var dismiss

    @ObservedObject var notionController: NotionController

    @State var storageLocation: StorageLocation = .iCloud
    @State var title = ""
    @State var showingError = false

    var body: some View {
        NavigationView {
            Form {
                Picker("Location", selection: $storageLocation) {
                    ForEach(StorageLocation.allCases) {
                        Text($0.rawValue)
                            .disabled($0 == .notion)
                            .tag($0)
                    }
                }
                TextField("Title", text: $title)
            }
            .navigationTitle("New Board")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            do {
                                try CloudController.shared.createICloudBoard(title: title)
                                dismiss()
                            } catch {
                                showingError = true
                                print(error)
                            }
                        }
                    }
                    .disabled(title.isEmpty || storageLocation == .notion)
                }
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
        .alert("Failed to Create Board", isPresented: $showingError) {
            Button("OK", action: { })
        }
    }
}

struct CreateBoardView_Previews: PreviewProvider {
    static var previews: some View {
        CreateBoardView(notionController: .shared)
    }
}
