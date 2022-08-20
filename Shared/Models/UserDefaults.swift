//
//  UserDefaults.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-01.
//

import Foundation

extension UserDefaults {
    
    struct Key {
        static let whatsNewVersion = "whatsNewVersion"
        static let notionIntegrationToken = "notionIntegrationToken"
        static let sortBoards = "sortBoards"
        static let showColumnColors = "showColumnColors"

        // Debug
        static let debugNotionIntegrationToken = "debugNotionIntegrationToken"
    }
    
    func register() {
        register(defaults: [
            Key.whatsNewVersion: 0,
            Key.notionIntegrationToken: "",
            Key.sortBoards: SettingsView.Sort.name.rawValue,
            Key.showColumnColors: true,
            
            Key.debugNotionIntegrationToken: ""
        ])
    }
    
}
