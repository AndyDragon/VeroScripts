//
//  VeroScriptsApp.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-01-03.
//

import SwiftUI

@main
struct VeroScriptsApp: App {
    @State var checkingForUpdates = false
    @State var versionCheckResult: VersionCheckResult = .complete
    @State var versionCheckToast = VersionCheckToast()
    
    var body: some Scene {
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            versionCheckResult: $versionCheckResult,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/veroscripts/version.json")
        WindowGroup {
            ContentView(appState)
        }
        .commands {
            CommandGroup(replacing: .appSettings, addition: {
                Button(action: {
                    appState.checkForUpdates(true)
                }, label: {
                    Text("Check for updates...")
                })
                .disabled(checkingForUpdates)
            })
            CommandGroup(replacing: CommandGroupPlacement.newItem) { }
        }
    }
}
