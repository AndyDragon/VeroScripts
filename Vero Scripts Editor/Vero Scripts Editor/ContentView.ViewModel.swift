//
//  ContentView.ViewModel.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-12-17.
//

import SwiftUI

extension ContentView {
    @Observable
    class ViewModel {
        var catalog = ObservableCatalog()
        var selectedPage: ObservablePage?
        var selectedTemplate: ObservableTemplate?
        var ignoreDirty: Bool = false
        var isDirty: Bool {
            catalog.isDirty && !ignoreDirty
        }
        var isShowingDocumentDirtyAlert = false

        var tagSource: TagSourceCase = .commonPageTag
        var firstFeature: Bool = false
        var userLevel: MembershipCase = .commonArtist
        var userAlias = "alphabeta"
        var yourName = "omegazeta"
        var yourFirstName = "Omega"
        var pageStaffLevel: StaffLevelCase = .mod

        init() {}
    }
}
