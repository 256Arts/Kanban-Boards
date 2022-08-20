//
//  WelcomeView.swift
//  Kanban Boards
//
//  Created by Jayden Irwin on 2022-05-03.
//

import SwiftUI

struct WelcomeView: View {
    
    #if os(macOS)
    let buttonTextColor = NSColor.windowBackgroundColor
    #else
    let buttonTextColor = UIColor.systemBackground
    #endif
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("This app uses Notion to store your boards.")
                
                Spacer()
                
                Link(destination: URL(string: "https://www.notion.so/")!) {
                    Text("Sign Up for Notion")
                        .font(.headline)
                        .foregroundColor(Color(buttonTextColor))
                        .frame(idealWidth: 500, maxWidth: 500)
                }
                .buttonStyle(.borderedProminent)
                
                NavigationLink {
                    NotionIntegrationView()
                } label: {
                    Text("Sign Into Notion")
                        .font(.headline)
                        .foregroundColor(Color(buttonTextColor))
                        .frame(idealWidth: 500, maxWidth: 500)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .controlSize(.large)
            .navigationTitle("Welcome")
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
