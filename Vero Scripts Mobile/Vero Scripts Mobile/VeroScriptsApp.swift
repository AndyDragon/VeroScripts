//
//  VeroScriptsApp.swift
//  Vero Scripts Mobile
//
//  Created by Andrew Forget on 2025-02-02.
//

import SwiftUI
import SwiftyBeaver

struct ShowAboutAction {
    typealias Action = () -> Void
    let action: Action
    func callAsFunction() {
        action()
    }
}
struct ShowAboutActionKey: EnvironmentKey {
    static var defaultValue: ShowAboutAction? = nil
}

struct ShowSettingsAction {
    typealias Action = () -> Void
    let action: Action
    func callAsFunction() {
        action()
    }
}
struct ShowSettingsActionKey: EnvironmentKey {
    static var defaultValue: ShowSettingsAction? = nil
}

extension EnvironmentValues {
    var showAbout: ShowAboutAction? {
        get { self[ShowAboutActionKey.self] }
        set { self[ShowAboutActionKey.self] = newValue }
    }
    var showSettings: ShowSettingsAction? {
        get { self[ShowSettingsActionKey.self] }
        set { self[ShowSettingsActionKey.self] = newValue }
    }
}

@main
struct VeroScriptsApp: App {
    @State private var showingAboutView = false
    @State private var showingSettingsView = false

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
        WindowGroup {
            ContentView()
                .sheet(isPresented: $showingAboutView) {
                    AboutView(packages: [
                        "SwiftyBeaver": [
                            "SwiftyBeaver ([Github profile](https://github.com/SwiftyBeaver))",
                        ],
                        "ToastView-SwiftUI": [
                            "Gaurav Tak ([Github profile](https://github.com/gauravtakroro))",
                            "modified by AndyDragon ([Github profile](https://github.com/AndyDragon))",
                        ],
                    ])
                    .presentationDetents([.height(440)])
                }
                .environment(\.showAbout, ShowAboutAction(action: {
                    showingAboutView.toggle()
                }))
                .sheet(isPresented: $showingSettingsView) {
                    SettingsView()
                        .presentationDetents([.height(440)])
                }
                .environment(\.showSettings, ShowSettingsAction(action: {
                    showingSettingsView.toggle()
                }))
                .onDisappear {
                    logger.info("End of session")
                    logger.info("==============================================================================")
                }
        }
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
