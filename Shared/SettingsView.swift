//
//  SettingsView.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-02.
//

import SwiftUI

struct SettingsView: View {

    enum Sort: String, CaseIterable, Identifiable {
        case name = "Name"
        case dateModified = "Date Modified"

        var id: Self { self }
    }

    @AppStorage(UserDefaults.Key.sortBoards) private var sortBoards = Sort.name.rawValue
    @AppStorage(UserDefaults.Key.showColumnColors) private var showColumnColors = true

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Sort Boards", selection: $sortBoards) {
                        ForEach(Sort.allCases) { sort in
                            Text(sort.rawValue)
                                .tag(sort.rawValue)
                        }
                    }
                    Toggle("Column Colors", isOn: $showColumnColors)
                }
                Section {
                    NavigationLink("Notion Integration") {
                        NotionIntegrationView()
                    }
                    #if DEBUG
                    Button("Swap to/from Debug Token") {
                        let oldToken = UserDefaults.standard.string(forKey: UserDefaults.Key.notionIntegrationToken)
                        let newToken = UserDefaults.standard.string(forKey: UserDefaults.Key.debugNotionIntegrationToken)
                        UserDefaults.standard.set(newToken, forKey: UserDefaults.Key.notionIntegrationToken)
                        UserDefaults.standard.set(oldToken, forKey: UserDefaults.Key.debugNotionIntegrationToken)

                        NotionController.shared = NotionController(integrationToken: newToken ?? "")
                        BoardsController.shared.fetchBoards()
                    }
                    .tint(Color.blue)
                    #endif
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
