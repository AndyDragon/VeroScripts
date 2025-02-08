//
//  VeroScriptsEditorApp.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-12-29.
//

import SwiftUI
import SwiftyBeaver

@main
struct VeroScriptsEditorApp: App {
    @Environment(\.openWindow) private var openWindow

#if STANDALONE
    @State var checkingForUpdates = false
    @State var versionCheckResult: VersionCheckResult = .complete
    @State var versionCheckToast = VersionCheckToast()
#endif
    @ObservedObject var commandModel = AppCommandModel()

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
            versionLocation: "https://vero.andydragon.com/static/data/veroscriptseditor/version.json")
#endif
        WindowGroup {
#if STANDALONE
            ContentView(appState)
                .environmentObject(commandModel)
#else
            ContentView()
                .environmentObject(commandModel)
#endif
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(action: {
                    logger.verbose("Open about view", context: "User")

                    // Open the "about" window using the id "about"
                    openWindow(id: "about")
                }, label: {
                    Text("About \(Bundle.main.displayName ?? "Vero Scripts Editor")")
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
            CommandGroup(replacing: .saveItem) { }
            CommandGroup(replacing: .newItem, addition: {
                Button(
                    action: {
                        logger.verbose("Manual reload pages catalog", context: "User")

                        // Manually reload the page catalog using the command model
                        commandModel.reloadPageCatalog.toggle()
                    },
                    label: {
                        Text("Reload page catalog...")
                    }
                )
                .keyboardShortcut("r", modifiers: [.command, .shift])
            })
            CommandMenu("Report") {
                Button(action: {
                    logger.verbose("Save report from menu", context: "User")

                    // Copies a report of the changes to the clipboard
                    commandModel.saveReport.toggle()
                }, label: {
                    Text("Save report to file")
                })
                .keyboardShortcut("r", modifiers: [.command])

                Button(action: {
                    logger.verbose("Copy report from menu", context: "User")

                    // Copies a report of the changes to the clipboard
                    commandModel.copyReport.toggle()
                }, label: {
                    Text("Copy report to clipboard")
                })
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
        
        // About view window with id "about"
        Window("About \(Bundle.main.displayName ?? "Vero Scripts Editor")", id: "about") {
            AboutView(packages: [
                "swiftui-introspect": [
                    "Siteline ([Github profile](https://github.com/siteline))"
                ],
                "SwiftyBeaver": [
                    "SwiftyBeaver ([Github profile](https://github.com/SwiftyBeaver))"
                ],
                "SystemColors": [
                    "Denis ([Github profile](https://github.com/diniska))"
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
            return DocumentManager.default.canTerminate()
        }

        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }

        func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
            return DocumentManager.default.canTerminate() ? .terminateNow : .terminateCancel
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

protocol DocumentManagerDelegate {
    func onCanTerminate() -> Bool
}

class DocumentManager {
    static var `default` = DocumentManager()

    private var receivers: [DocumentManagerDelegate] = []

    func registerReceiver(receiver: DocumentManagerDelegate) {
        receivers.append(receiver)
    }

    func canTerminate() -> Bool {
        for receiver in receivers {
            if !receiver.onCanTerminate() {
                return false
            }
        }
        return true
    }
}

class AppCommandModel: ObservableObject {
    @Published var copyReport: Bool = false
    @Published var saveReport: Bool = false
    @Published var reloadPageCatalog: Bool = false
}
