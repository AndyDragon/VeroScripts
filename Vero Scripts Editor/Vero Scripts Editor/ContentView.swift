//
//  ContentView.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-12-29.
//

import AlertToast
import SwiftUI

struct ContentView: View {
    //@Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var isDarkModeOn = true

    @Environment(\.openURL) private var openURL

    @State private var viewModel = ViewModel()
    @State private var toastManager = ToastManager()
    @FocusState private var focusedField: FocusField?
    @State private var documentDirtyAlertConfirmation = "Are you sure you wish to quit?"
    @State private var documentDirtyAfterDismissAction: () -> Void = {}
    @State private var selectedMissingPageTemplate: String?
    @State private var selectedTemplate: ObservableTemplate?

    private var appState: VersionCheckAppState
    private let labelWidth: CGFloat = 80

    private func templatePageFromPage(_ page: ObservablePage) -> ObservableTemplatePage? {
        return viewModel.catalog.templatesCatalog.pages.first(where: { $0.pageId == page.pageId })
    }

    private var selectedPageTemplates: [ObservableTemplate]? {
        if let selectedPage = viewModel.selectedPage, let templatePage = templatePageFromPage(selectedPage) {
            return templatePage.templates
        }
        return nil
    }

    private var missingPageTemplates: [String] {
        if let selectedPage = viewModel.selectedPage, let currentPageTemplates = selectedPageTemplates?.map({ $0.name }) {
            switch selectedPage.hub {
            case "click":
                let allPageTemplates = [
                    "feature",
                    "comment",
                    "first comment",
                    "community comment",
                    "first community comment",
                    "hub comment",
                    "first hub comment",
                    "original post"
                ]
                return allPageTemplates.filter({ !currentPageTemplates.contains($0)})
            case "snap":
                let allPageTemplates = [
                    "feature",
                    "comment",
                    "first comment",
                    "raw comment",
                    "first raw comment",
                    "community comment",
                    "first community comment",
                    "raw community comment",
                    "first raw community comment",
                    "original post"
                ]
                return allPageTemplates.filter({ !currentPageTemplates.contains($0)})
            default:
                let allPageTemplates = [
                    "feature",
                    "comment",
                    "first comment",
                    "original post"
                ]
                return allPageTemplates.filter({ !currentPageTemplates.contains($0)})
            }
        }
        return []
    }

    init(_ appState: VersionCheckAppState) {
        self.appState = appState
    }

    var body: some View {
        NavigationSplitView(sidebar: {
            ZStack {
                VStack(alignment: .leading) {
                    Text("Page:")
                    Picker("", selection: $viewModel.selectedPage.onChange { value in
                        navigateToPage(.same)
                    }) {
                        ForEach(viewModel.catalog.pages) { page in
                            HStack {
                                Text(page.displayName)
                                Spacer()
                                if page.isDirty || templatePageFromPage(page)?.isDirty ?? false {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white, .red)
                                        .help("One or more templates has been modified")
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .environment(\.layoutDirection, .leftToRight)
                            .tag(page)
                        }
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                    .focused($focusedField, equals: .pagePicker)
                    .onKeyPress(phases: .down) { keyPress in
                        return navigateToPageWithArrows(keyPress)
                    }
                    .onKeyPress(characters: .alphanumerics) { keyPress in
                        return navigateToPageWithPrefix(keyPress)
                    }
                    .padding([.bottom], 20)

                    if let selectedPageTemplates {
                        Text("Scripts:")
                        List(selectedPageTemplates.sorted(by: { $0.name < $1.name }), selection: $selectedTemplate) { template in
                            NavigationLink(value: template) {
                                HStack {
                                    Text(template.name)
                                    Spacer()
                                    if template.isDirty {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white, .red)
                                            .help("This template has been modified")
                                    }
                                }
                            }
                        }
                        .listStyle(.sidebar)
                        .navigationSplitViewColumnWidth(min: 240, ideal: 320)
                        .frame(minWidth: 240)
                        Spacer()
                        if !missingPageTemplates.isEmpty {
                            Text("Missing scripts:")
                            HStack(alignment: .center) {
                                Picker("", selection: $selectedMissingPageTemplate)
                                {
                                    ForEach(missingPageTemplates, id: \.self) { templateName in
                                        Text(templateName)
                                    }
                                }
                                Button(action: {
                                    if let selectedMissingPageTemplate, !selectedMissingPageTemplate.isEmpty {
                                        if let selectedPage = viewModel.selectedPage, let templatePage = templatePageFromPage(selectedPage) {
                                            let template = ObservableTemplate(name: selectedMissingPageTemplate, template: "- script -", forceDirty: true)
                                            templatePage.templates.append(template)
                                            selectedTemplate = template
                                        }
                                    }
                                    selectedMissingPageTemplate = nil
                                }) {
                                    Text("Add")
                                }
                                .disabled(selectedMissingPageTemplate == nil)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                ToastDismissShield(toastManager)
            }
            .blur(radius: toastManager.isShowingAnyToast ? 4 : 0)
            .allowsHitTesting(!toastManager.isShowingAnyToast)
        }, detail: {
            ZStack {
                if let selectedTemplate {
                    TemplateEditorView(toastManager: toastManager, viewModel: viewModel, selectedTemplate: selectedTemplate, focusedField: $focusedField)
                } else {
                    WelcomeView()
                }
                ToastDismissShield(toastManager)
            }
            .blur(radius: toastManager.isShowingAnyToast ? 4 : 0)
            .allowsHitTesting(!toastManager.isShowingAnyToast)
        })
        .navigationTitle("Vero Scripts Editor")
        .navigationSubtitle(viewModel.isDirty ? "templates modified" : "")
        .frame(minWidth: 1280, minHeight: 800)
        .background(Color.BackgroundColor)
        .sheet(isPresented: $viewModel.isShowingDocumentDirtyAlert) {
            DocumentDirtySheet(
                isShowing: $viewModel.isShowingDocumentDirtyAlert,
                confirmationText: $documentDirtyAlertConfirmation,
                dismissAction: {
                    documentDirtyAfterDismissAction()
                    documentDirtyAfterDismissAction = {}
                },
                cancelAction: {
                    documentDirtyAfterDismissAction = {}
                })
        }
        .modifier(ToastModifier(toastManager))
        .onAppear(perform: {
            DocumentManager.default.registerReceiver(receiver: self)
        })
        .task {
            toastManager.showProgressToast = showProgressToast
            toastManager.showToast = showToast
            toastManager.showToastWithCompletion = showToastWithCompletion

            await loadPageCatalog()
        }
        .preferredColorScheme(isDarkModeOn ? .dark : .light)
    }

    private func loadPageCatalog() async {
        do {
            let pagesUrl = URL(string: "https://vero.andydragon.com/static/data/pages.json")!
            let pagesCatalog = try await URLSession.shared.decode(ScriptsCatalog.self, from: pagesUrl)
            var pages = [ObservablePage]()
            for hubPair in (pagesCatalog.hubs) {
                for hubPage in hubPair.value {
                    pages.append(ObservablePage(hub: hubPair.key, page: hubPage))
                }
            }
            viewModel.catalog.pages.removeAll()
            viewModel.catalog.pages.append(
                contentsOf: pages.sorted(by: {
                    if $0.hub == "other" && $1.hub == "other" {
                        return $0.name < $1.name
                    }
                    if $0.hub == "other" {
                        return false
                    }
                    if $1.hub == "other" {
                        return true
                    }
                    return "\($0.hub)_\($0.name)" < "\($1.hub)_\($1.name)"
                }))
            viewModel.catalog.waitingForPages = false
            let lastPage = UserDefaults.standard.string(forKey: "Page") ?? ""
            viewModel.selectedPage = viewModel.catalog.pages.first(where: { $0.pageId == lastPage })
            if viewModel.selectedPage == nil {
                viewModel.selectedPage = viewModel.catalog.pages.first ?? nil
            }

            // Delay the start of the templates download so the window can be ready faster
            try await Task.sleep(nanoseconds: 200_000_000)

            let templatesUrl = URL(string: "https://vero.andydragon.com/static/data/templates.json")!
            let templatesCatalog = try await URLSession.shared.decode(TemplateCatalog.self, from: templatesUrl)
            viewModel.catalog.templatesCatalog = ObservableTemplateCatalog(
                pages: templatesCatalog.pages.map({ templatePage in
                    ObservableTemplatePage(name: templatePage.name, templates: templatePage.templates.map({ ObservableTemplate(template: $0) }))
                }),
                specialTemplates: templatesCatalog.specialTemplates.map({ ObservableTemplate(template: $0) }))
            viewModel.catalog.waitingForTemplates = false

            do {
                // Delay the start of the disallowed list download so the window can be ready faster
                try await Task.sleep(nanoseconds: 100_000_000)

                appState.checkForUpdates()
            } catch {
                // do nothing, the version check is not critical
                debugPrint(error.localizedDescription)
            }
        } catch {
            toastManager.showToastWithCompletion(
                .error(.red),
                "Failed to load pages",
                "The application requires the catalog to perform its operations: \(error.localizedDescription)\n\n" +
                "Click here to try again immediately or wait \(ToastDuration.CatalogLoadFailure.rawValue) seconds to automatically try again.",
                .CatalogLoadFailure,
                {
                    DispatchQueue.main.async {
                        Task {
                            await loadPageCatalog()
                        }
                    }
                },
                {
                    DispatchQueue.main.async {
                        Task {
                            await loadPageCatalog()
                        }
                    }
                }
            )
        }
    }

    private func delayAndTerminate() {
        viewModel.ignoreDirty = true
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.2,
            execute: {
                NSApplication.shared.terminate(nil)
            })
    }

    private func navigateToPage(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(viewModel.catalog.pages, viewModel.selectedPage, direction)
        if change {
            if direction != .same {
                viewModel.selectedPage = newValue
            }
            selectedTemplate = nil
            UserDefaults.standard.set(viewModel.selectedPage?.pageId ?? "", forKey: "Page")
        }
    }

    private func navigateToPageWithArrows(_ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToPage(direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToPageWithPrefix(_ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(viewModel.catalog.pages.map({ $0.name }), viewModel.selectedPage?.name ?? "", keyPress.characters.lowercased())
        if change {
            if let newPage = viewModel.catalog.pages.first(where: { $0.name == newValue }) {
                viewModel.selectedPage = newPage
                selectedTemplate = nil
                UserDefaults.standard.set(viewModel.selectedPage?.pageId ?? "", forKey: "Page")
            }
            return .handled
        }
        return .ignored
    }
}

extension ContentView: DocumentManagerDelegate {
    func onCanTerminate() -> Bool {
        if viewModel.isDirty {
            documentDirtyAfterDismissAction = {
                delayAndTerminate()
            }
            viewModel.isShowingDocumentDirtyAlert.toggle()
        }
        return !viewModel.isDirty
    }
}

enum ToastDuration: Int {
    case Blocking = 0
    case Success = 1
    case Failure = 5
    case CatalogLoadFailure = 10
    case LongFailure = 30
}

extension ContentView {
    struct ToastModifier: ViewModifier {
        @Bindable private var toastManager: ToastManager

        init(
            _ toastManager: ToastManager
        ) {
            self.toastManager = toastManager
        }

        func body(content: Content) -> some View {
            content
                .toast(
                    isPresenting: $toastManager.isShowingToast,
                    duration: 0,
                    tapToDismiss: true,
                    offsetY: 32,
                    alert: {
                        AlertToast(
                            displayMode: .hud,
                            type: toastManager.toastType,
                            title: toastManager.toastText,
                            subTitle: toastManager.toastSubTitle)
                    },
                    onTap: toastManager.toastTapAction,
                    completion: toastManager.toastCompletionAction
                )
                .toast(
                    isPresenting: $toastManager.isShowingProgressToast,
                    duration: 0,
                    tapToDismiss: false,
                    offsetY: 32,
                    alert: {
                        AlertToast(
                            displayMode: .hud,
                            type: .loading,
                            title: toastManager.progressToastText)
                    }
                )
        }
    }

    @Observable
    class ToastManager {
        var isShowingToast = false
        var isShowingProgressToast = false
        var toastId: UUID?
        var toastType: AlertToast.AlertType = .regular
        var toastText = ""
        var progressToastText = ""
        var toastSubTitle = ""
        var toastDuration = 3.0
        var toastTapAction: () -> Void = {}
        var toastCompletionAction: () -> Void = {}
        var isShowingAnyToast: Bool {
            isShowingToast || isShowingProgressToast
        }

        var showProgressToast: (
            _ text: String
        ) -> Void = {_ in }

        var showToast: (
            _ type: AlertToast.AlertType,
            _ text: String,
            _ subTitle: String,
            _ duration: ToastDuration,
            _ onTap: @escaping () -> Void
        ) -> Void = {_, _, _, _, _ in }

        var showToastWithCompletion: (
            _ type: AlertToast.AlertType,
            _ text: String,
            _ subTitle: String,
            _ duration: ToastDuration,
            _ onTap: @escaping () -> Void,
            _ onCompletion: @escaping () -> Void
        ) -> Void = {_, _, _, _, _, _ in }

        func showCompletedToast(
            _ text: String,
            _ subTitle: String = "",
            _ duration: ToastDuration = .Success,
            _ onTap: @escaping () -> Void = {}
        ) -> Void {
            showToast(.complete(.green), text, subTitle, duration, onTap)
        }

        func showFailureToast(
            _ text: String,
            _ subTitle: String = "",
            _ duration: ToastDuration = .Failure,
            _ onTap: @escaping () -> Void = {}
        ) {
            showToast(.error(.red), text, subTitle, duration, onTap)
        }

        func showBlockingFailureToast(
            _ text: String,
            _ subTitle: String = "",
            _ onTap: @escaping () -> Void = {}
        ) {
            showToast(.error(.red), text, subTitle, .Blocking, onTap)
        }

        func hideAnyToast(_ onlyProgressToast: Bool = false) {
            if isShowingToast && !onlyProgressToast {
                toastId = nil
                isShowingToast.toggle()
            }
            if isShowingProgressToast {
                isShowingProgressToast.toggle()
            }
        }
    }

    func showProgressToast(
        _ text: String
    ) {
        if !toastManager.isShowingProgressToast {
            withAnimation {
                toastManager.progressToastText = text
                focusedField = nil
                toastManager.isShowingProgressToast.toggle()
            }
        }
    }

    func showToast(
        _ type: AlertToast.AlertType,
        _ text: String,
        _ subTitle: String = "",
        _ duration: ToastDuration = .Success,
        _ onTap: @escaping () -> Void = {}
    ) {
        if toastManager.isShowingToast {
            toastManager.toastId = nil
            toastManager.isShowingToast.toggle()
        }

        let savedFocusedField = focusedField

        let cleanup: (_ : Bool) -> Void = { toggle in
            toastManager.toastId = nil
            if toggle {
                toastManager.isShowingToast.toggle()
            }
            focusedField = savedFocusedField
        }

        withAnimation {
            toastManager.toastType = type
            toastManager.toastText = text
            toastManager.toastSubTitle = subTitle
            toastManager.toastTapAction = {
                cleanup(false)
                onTap()
            }
            toastManager.toastCompletionAction = {
                cleanup(false)
            }
            focusedField = nil
            toastManager.toastId = UUID()
            toastManager.isShowingToast.toggle()
        }

        if duration != .Blocking {
            let expectedToastId = toastManager.toastId
            DispatchQueue.main.asyncAfter(
                deadline: .now() + .seconds(duration.rawValue),
                execute: {
                    if toastManager.isShowingToast && toastManager.toastId == expectedToastId {
                        cleanup(true)
                    }
                })
        }
    }

    func showToastWithCompletion(
        _ type: AlertToast.AlertType,
        _ text: String,
        _ subTitle: String = "",
        _ duration: ToastDuration = .Success,
        _ onTap: @escaping () -> Void = {},
        _ onCompletion: @escaping () -> Void = {}
    ) {
        if toastManager.isShowingToast {
            toastManager.toastId = nil
            toastManager.isShowingToast.toggle()
        }

        let savedFocusedField = focusedField

        let cleanup: (_ : Bool) -> Void = { toggle in
            toastManager.toastId = nil
            if toggle {
                toastManager.isShowingToast.toggle()
            }
            focusedField = savedFocusedField
        }

        withAnimation {
            toastManager.toastType = type
            toastManager.toastText = text
            toastManager.toastSubTitle = subTitle
            toastManager.toastTapAction = {
                cleanup(false)
                onTap()
            }
            toastManager.toastCompletionAction = {
                cleanup(false)
                onCompletion()
            }
            focusedField = nil
            toastManager.toastId = UUID()
            toastManager.isShowingToast.toggle()
        }

        if duration != .Blocking {
            let expectedToastId = toastManager.toastId
            DispatchQueue.main.asyncAfter(
                deadline: .now() + .seconds(duration.rawValue),
                execute: {
                    if toastManager.isShowingToast && toastManager.toastId == expectedToastId {
                        cleanup(true)
                    }
                })
        }
    }

    enum ToastDuration: Int {
        case Blocking = 0
        case Success = 1
        case Failure = 5
        case CatalogLoadFailure = 10
        case LongFailure = 30
    }
}
