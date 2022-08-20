//
//  CreateColumnView.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-02.
//

import SwiftUI
import NotionSwift

struct CreateColumnView: View {

    @Environment(\.dismiss) var dismiss

    @ObservedObject var board: Board

    @State var title = ""
    @State var colorName: Column.NotionColor = .default
    @State var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                Picker("Color", selection: $colorName) {
                    ForEach(Column.NotionColor.allCases) { colorName in
                        Label {
                            Text(colorName.rawValue.capitalized)
                        } icon: {
                            Image(systemName: "circle.fill")
                                .foregroundColor(colorName.color)
                        }
                        .tag(colorName)
                    }
                }
                .pickerStyle(.inline)
            }
            .navigationTitle("New Column")
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
                                try await board.createColumn(name: title)
                                dismiss()
                            } catch let error as NotionClientError {
                                errorMessage = error.betterDescription
                                print(error)
                            } catch {
                                errorMessage = error.localizedDescription
                                print(error)
                            }
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
        .alert("Failed to Create Column", isPresented: Binding(get: {
            !errorMessage.isEmpty
        }, set: { newValue in
            errorMessage = newValue ? " " : ""
        })) {
            Button("OK", action: { })
        } message: {
            Text(errorMessage)
        }
    }
}

struct CreateColumnView_Previews: PreviewProvider {
    static var previews: some View {
        CreateColumnView(board: .debugPreviewBoard)
    }
}
