//
//  Kanban_BoardsApp.swift
//  Shared
//
//  Created by Jayden Irwin on 2022-05-01.
//

import SwiftUI

@main
struct Kanban_BoardsApp: App {
    
    static let appWhatsNewVersion = 1
    
    @AppStorage(UserDefaults.Key.notionIntegrationToken) var notionIntegrationToken = ""
    
    init() {
        UserDefaults.standard.register()
    }
    
    var body: some Scene {
        WindowGroup {
            if notionIntegrationToken.isEmpty {
                WelcomeView()
            } else {
                BoardsList()
            }
        }
    }
}
