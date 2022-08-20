//
//  NotionIntegrationView.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-01.
//

import SwiftUI

struct NotionIntegrationView: View {
    
    @AppStorage(UserDefaults.Key.notionIntegrationToken) var notionIntegrationToken = ""
    
    @State var token = UserDefaults.standard.string(forKey: UserDefaults.Key.notionIntegrationToken) ?? ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter an integration token for your Notion workspace.")

            Text("You can get one by going to Settings & Members > Integrations > \"Develop your own integrations\" > New Integration.")

            HStack {
                SecureField("Integration token", text: $token) {
                    notionIntegrationToken = token
                    NotionController.shared = .init(integrationToken: token)
                }
                .textFieldStyle(.roundedBorder)

                Button("Copy") {
                    #if os(macOS)
                    NSPasteboard.general.setString(notionIntegrationToken, forType: .string)
                    #else
                    UIPasteboard.general.string = notionIntegrationToken
                    #endif
                }
            }

            Text("Then ensure you share each database with this integration.")

            Spacer()
        }
        .padding()
        .navigationTitle("Notion Integration")
    }
}

struct NotionAuthorizationView_Previews: PreviewProvider {
    static var previews: some View {
        NotionIntegrationView()
    }
}
