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

#if STANDALONE
    @State var checkingForUpdates = false
    @State var versionCheckResult: VersionCheckResult = .complete
    @State var versionCheckToast = VersionCheckToast()
#endif

    let logger = SwiftyBeaver.self
    let loggerConsole = ConsoleDestination()
    let loggerFile = FileDestination()

    init() {
        loggerConsole.logPrintWay = .logger(subsystem: "Main", category: "UI")
        loggerFile.logFileURL = getDocumentsDirectory().appendingPathComponent("\(Bundle.main.displayName ?? "Vero Scripts").log", conformingTo: .log)
        logger.addDestination(loggerConsole)
        logger.addDestination(loggerFile)
    }

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
#if STANDALONE
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            versionCheckResult: $versionCheckResult,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/veroscripts/version.json")
#endif
        WindowGroup {
#if STANDALONE
            ContentView(appState)
#else
            ContentView()
#if SCREENSHOT
                .frame(width: 1280, height: 748)
                .frame(minWidth: 1280, maxWidth: 1280, minHeight: 748, maxHeight: 748)
#else
                .frame(minWidth: 1024, minHeight: 600)
#endif
#endif
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
#if STANDALONE
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
#endif
            CommandGroup(replacing: CommandGroupPlacement.newItem) { }
        }
        
        // About view window with id "about"
        Window("About \(Bundle.main.displayName ?? "Vero Scripts")", id: "about") {
            AboutView(packages: [
                "Kingfisher": [
                    "Wei Wang ([Github profile](https://github.com/onevcat))",
                ],
                "SystemColors": [
                    "Denis ([Github profile](https://github.com/diniska))"
                ],
                "SwiftSoup": [
                    "Nabil Chatbi ([Github profile](https://github.com/scinfu))",
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

    class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
        private let logger = SwiftyBeaver.self

        func applicationWillFinishLaunching(_ notification: Notification) {
            logger.info("==============================================================================")
            logger.info("Start of session")
        }

        func applicationDidFinishLaunching(_ notification: Notification) {
            let mainWindow = NSApp.windows[0]
            mainWindow.delegate = self
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            return true
        }

        func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
            return .terminateNow
        }

        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }

        func applicationWillTerminate(_ notification: Notification) {
            logger.info("End of session")
            logger.info("==============================================================================")
        }
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
