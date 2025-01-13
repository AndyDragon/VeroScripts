//
//  VeroScriptsApp.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-01-03.
//

import SwiftUI
import SwiftyBeaver

@main
struct VeroScriptsApp: App {
    @Environment(\.openWindow) private var openWindow

    @State var checkingForUpdates = false
    @State var versionCheckResult: VersionCheckResult = .complete
    @State var versionCheckToast = VersionCheckToast()
    
    let logger = SwiftyBeaver.self
    let loggerConsole = ConsoleDestination()
    let loggerFile = FileDestination()

    init() {
        loggerConsole.logPrintWay = .logger(subsystem: "Main", category: "UI")
        loggerFile.logFileURL = getDocumentsDirectory().appendingPathComponent("\(Bundle.main.displayName ?? "Vero Scripts").log", conformingTo: .log)
        logger.addDestination(loggerConsole)
        logger.addDestination(loggerFile)
        logger.info("==============================================================================")
        logger.info("Start of session")
    }

    var body: some Scene {
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            versionCheckResult: $versionCheckResult,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/veroscripts/version.json")
        WindowGroup {
            ContentView(appState)
                .onDisappear {
                    logger.info("End of session")
                    logger.info("==============================================================================")
                }
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    logger.verbose("Open about view", context: "User")

                    // Open the "about" window using the id "about"
                    openWindow(id: "about")
                }, label: {
                    Text("About \(Bundle.main.displayName ?? "Vero Scripts")")
                })
            }
            CommandGroup(replacing: .appSettings, addition: {
                Button(action: {
                    logger.verbose("Manual check for updates", context: "User")

                    // Manually check for updates
                    appState.checkForUpdates(true)
                }, label: {
                    Text("Check for updates...")
                })
                .disabled(checkingForUpdates)
            })
            CommandGroup(replacing: CommandGroupPlacement.newItem) { }
        }
        
        // About view window with id "about"
        Window("About \(Bundle.main.displayName ?? "Vero Scripts")", id: "about") {
            AboutView(packages: [
                "SystemColors": [
                    "Denis ([Github profile](https://github.com/diniska))"
                ],
                "SwiftyBeaver": [
                    "SwiftyBeaver ([Github profile](https://github.com/SwiftyBeaver))"
                ],
                "ToastView-SwiftUI": [
                    "Gaurav Tak ([Github profile](https://github.com/gauravtakroro))",
                    "modified by AndyDragon ([Github profile](https://github.com/AndyDragon))"
                ]
            ])
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
