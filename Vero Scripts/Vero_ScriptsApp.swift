//
//  Vero_ScriptsApp.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-01-03.
//

import SwiftUI

struct VersionCheckToast {
    var appVersion: String
    var currentVersion: String
    var linkToCurrentVersion: String
    
    init(appVersion: String = "unknown", currentVersion: String = "unknown", linkToCurrentVersion: String = "") {
        self.appVersion = appVersion
        self.currentVersion = currentVersion
        self.linkToCurrentVersion = linkToCurrentVersion
    }
}

struct VersionCheckAppState {
    private var isCheckingForUpdates: Binding<Bool>
    var isShowingVersionAvailableToast: Binding<Bool>
    var isShowingVersionRequiredToast: Binding<Bool>
    var versionCheckToast: Binding<VersionCheckToast>
    
    init(
        isCheckingForUpdates: Binding<Bool>,
        isShowingVersionAvailableToast: Binding<Bool>,
        isShowingVersionRequiredToast: Binding<Bool>,
        versionCheckToast: Binding<VersionCheckToast>) {
        self.isCheckingForUpdates = isCheckingForUpdates
        self.isShowingVersionAvailableToast = isShowingVersionAvailableToast
        self.isShowingVersionRequiredToast = isShowingVersionRequiredToast
        self.versionCheckToast = versionCheckToast
    }
    
    func checkForUpdates() {
        isCheckingForUpdates.wrappedValue = true
        Task {
            try? await checkForUpdatesAsync()
        }
    }
    
    func resetCheckingForUpdates() {
        isCheckingForUpdates.wrappedValue = false
    }
    
    private func checkForUpdatesAsync() async throws -> Void {
        do {
            // Check version from server manifest
            let versionManifestUrl = URL(string: "https://vero.andydragon.com/static/data/version.json")!
            let versionManifest = try await URLSession.shared.decode(VersionManifest.self, from: versionManifestUrl)
            if Bundle.main.releaseVersionOlder(than: versionManifest.macOS.current) {
                DispatchQueue.main.async {
                    withAnimation {
                        versionCheckToast.wrappedValue = VersionCheckToast(
                            appVersion: Bundle.main.releaseVersionNumberPretty,
                            currentVersion: versionManifest.macOS.current,
                            linkToCurrentVersion: versionManifest.macOS.link)
                        if versionManifest.macOS.vital {
                            isShowingVersionRequiredToast.wrappedValue.toggle()
                        } else {
                            isShowingVersionAvailableToast.wrappedValue.toggle()
                        }
                    }
                }
            } else {
                resetCheckingForUpdates()
            }
        } catch {
            // do nothing, the version check is not critical
            debugPrint(error.localizedDescription)
        }
    }
}

@main
struct Vero_ScriptsApp: App {
    @State var checkingForUpdates = false
    @State var isShowingVersionAvailableToast: Bool = false
    @State var isShowingVersionRequiredToast: Bool = false
    @State var versionCheckToast = VersionCheckToast()
    
    var body: some Scene {
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            isShowingVersionAvailableToast: $isShowingVersionAvailableToast,
            isShowingVersionRequiredToast: $isShowingVersionRequiredToast,
            versionCheckToast: $versionCheckToast)
        WindowGroup {
            ContentView(appState)
        }
        .commands {
            CommandGroup(replacing: .appSettings, addition: {
                Button(action: {
                    appState.checkForUpdates()
                }, label: {
                    Text("Check for updates...")
                })
                .disabled(checkingForUpdates)
            })
        }
    }
}
