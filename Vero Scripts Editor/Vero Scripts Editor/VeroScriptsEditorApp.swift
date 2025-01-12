//
//  VeroScriptsEditorApp.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-12-29.
//

import SwiftUI

@main
struct VeroScriptsEditorApp: App {
    @Environment(\.openWindow) private var openWindow

    @State var checkingForUpdates = false
    @State var versionCheckResult: VersionCheckResult = .complete
    @State var versionCheckToast = VersionCheckToast()
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            versionCheckResult: $versionCheckResult,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/veroscriptseditor/version.json")
        WindowGroup {
            ContentView(appState)
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    // Open the "about" window using the id "about"
                    openWindow(id: "about")
                }, label: {
                    Text("About \(Bundle.main.displayName ?? "Vero Scripts Editor")")
                })
            }
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
        
        // About view window with id "about"
        Window("About \(Bundle.main.displayName ?? "Vero Scripts Editor")", id: "about") {
            AboutView()
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
    }

    class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
        func applicationDidFinishLaunching(_ notification: Notification) {
            let mainWindow = NSApp.windows[0]
            mainWindow.delegate = self
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            return false
        }

        func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
            return DocumentManager.default.canTerminate() ? .terminateNow : .terminateCancel
        }
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
