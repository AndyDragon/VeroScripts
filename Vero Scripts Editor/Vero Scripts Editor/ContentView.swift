//
//  ContentView.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-12-29.
//

import SwiftUI
import SwiftyBeaver

struct ContentView: View {
    @State private var isDarkModeOn = true

    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var commandModel: AppCommandModel

    @State private var viewModel = ViewModel()
    @FocusState private var focusedField: FocusField?
    @State private var documentDirtyAlertDismissLable = "Quit"
    @State private var documentDirtyAlertConfirmation = "Are you sure you wish to quit?"
    @State private var documentDirtyAfterSaveAction: (_ longPause: Bool) -> Void = { longPause in }
    @State private var documentDirtyAfterDismissAction: (_ longPause: Bool) -> Void = { longPause in }
    @State private var selectedMissingPageTemplate: String?
    @State private var selectedTemplate: ObservableTemplate?
    @State private var showingFileExporter = false
    @State private var reportDocument = ReportDocument()

    private let labelWidth: CGFloat = 80
    private let logger = SwiftyBeaver.self

    private var fileNameDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private func templatePageFromPage(_ page: ObservablePage) -> ObservableTemplatePage? {
        return viewModel.catalog.templatesCatalog.pages.first(where: { $0.pageId == page.pageId })
    }

    private func pageFromTemplatePage(_ templatePage: ObservableTemplatePage) -> ObservablePage? {
        return viewModel.catalog.pages.first(where: { $0.pageId == templatePage.pageId })
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

#if STANDALONE
    private let appState: VersionCheckAppState
    init(_ appState: VersionCheckAppState) {
        self.appState = appState
    }
#endif

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
                                            .tag(templateName)
                                    }
                                }
                                Button(action: {
                                    logger.verbose("Tapped add template", context: "User")
                                    if let selectedMissingPageTemplate, !selectedMissingPageTemplate.isEmpty {
                                        if let selectedPage = viewModel.selectedPage, let templatePage = templatePageFromPage(selectedPage) {
                                            let template = ObservableTemplate(name: selectedMissingPageTemplate, template: "- script -", forceDirty: true)
                                            templatePage.templates.append(template)
                                            selectedTemplate = template
                                            logger.verbose("Added new template", context: "System")
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
            }
        }, detail: {
            ZStack {
                if let selectedTemplate {
                    TemplateEditorView(viewModel: viewModel, selectedTemplate: selectedTemplate, focusedField: $focusedField) {
                        if let selectedPage = viewModel.selectedPage, let templatePage = templatePageFromPage(selectedPage) {
                            templatePage.templates.removeAll(where: { $0 == selectedTemplate })
                            self.selectedTemplate = nil
                            logger.verbose("Removed template", context: "System")
                        }
                    }
                } else {
                    WelcomeView()
                }

                FileExporterView()
            }
        })
        .background(Color.BackgroundColor)
        .sheet(isPresented: $viewModel.isShowingDocumentDirtyAlert) {
            DocumentDirtySheet(
                isShowing: $viewModel.isShowingDocumentDirtyAlert,
                confirmationText: documentDirtyAlertConfirmation,
                dismissLabel: documentDirtyAlertDismissLable,
                copyReportAction: {
                    if let report = generateReport() {
                        Pasteboard.copyToClipboard(report)
                        viewModel.showSuccessToast("Report generated!", "Copied the report of changes to the clipboard")
                        logger.verbose("Generated report of changes", context: "System")
                    }
                    documentDirtyAfterDismissAction(true)
                    documentDirtyAfterSaveAction = { longPause in }
                    documentDirtyAfterDismissAction = { longPause in }
                },
                saveReportAction: {
                    if let report = generateReport() {
                        reportDocument = ReportDocument(report: report)
                        showingFileExporter.toggle()
                    } else {
                        documentDirtyAfterDismissAction(true)
                        documentDirtyAfterSaveAction = { longPause in }
                        documentDirtyAfterDismissAction = { longPause in }
                    }
                },
                dismissAction: {
                    documentDirtyAfterDismissAction(false)
                    documentDirtyAfterSaveAction = { longPause in }
                    documentDirtyAfterDismissAction = { longPause in }
                },
                cancelAction: {
                    documentDirtyAfterSaveAction = { longPause in }
                    documentDirtyAfterDismissAction = { longPause in }
                })
        }
        .advancedToastView(toasts: $viewModel.toastViews)
#if STANDALONE
        .attachVersionCheckState(viewModel, appState) { url in
            openURL(url)
        }
        .navigationTitle("Vero Scripts Editor Standalone")
#else
        .navigationTitle("Vero Scripts Editor")
#endif
        .navigationSubtitle(viewModel.isDirty ? "templates modified" : "")
        .onAppear(perform: {
            DocumentManager.default.registerReceiver(receiver: self)
        })
        .task {
            let loadingPagesToast = viewModel.showToast(
                .progress,
                "Loading pages...",
                "Loading the page catalog from the server"
            )

            await loadPageCatalog()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                viewModel.dismissToast(loadingPagesToast)
            }
        }
        .onChange(of: commandModel.reloadPageCatalog) {
            if viewModel.isDirty {
                documentDirtyAlertDismissLable = "Reload"
                documentDirtyAlertConfirmation = "Are you sure you wish to reload the pages?"
                documentDirtyAfterDismissAction = { longPause in
                    reloadPages()
                }
                documentDirtyAfterSaveAction = { longPause in
                    reloadPages()
                }
                viewModel.isShowingDocumentDirtyAlert.toggle()
            } else {
                reloadPages()
            }
        }
        .onChange(of: commandModel.copyReport) {
            if let report = generateReport() {
                Pasteboard.copyToClipboard(report)
                viewModel.showSuccessToast("Report generated!", "Copied the report of changes to the clipboard")
                logger.verbose("Generated report of changes", context: "System")
            }
        }
        .onChange(of: commandModel.saveReport) {
            if let report = generateReport() {
                reportDocument = ReportDocument(report: report)
                showingFileExporter.toggle()
            }
        }
        .preferredColorScheme(isDarkModeOn ? .dark : .light)
    }

    fileprivate func FileExporterView() -> some View {
        HStack { }
            .frame(width: 0, height: 0)
            .fileExporter(
                isPresented: $showingFileExporter,
                document: reportDocument,
                contentType: .plainText,
                defaultFilename: "Change report - \(fileNameDateFormatter.string(from: Date.now)).txt"
            ) { result in
                switch result {
                case .success(_):
                    logger.verbose("Saved the report", context: "System")
                    documentDirtyAfterSaveAction(false)
                    documentDirtyAfterSaveAction = { longPause in }
                    documentDirtyAfterDismissAction = { longPause in }
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            .fileExporterFilenameLabel("Save report as: ") // filename label
            .fileDialogConfirmationLabel("Save report")
    }

    private func reloadPages() {
        Task {
            selectedTemplate = nil
            let loadingPagesToast = viewModel.showToast(
                .progress,
                "Loading pages...",
                "Loading the page catalog from the server"
            )

            await loadPageCatalog()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                viewModel.dismissToast(loadingPagesToast)
            }
        }
    }

    private func loadPageCatalog() async {
        logger.verbose("Loading page catalog from server", context: "System")

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

            logger.verbose("Loaded page catalog from server with \(viewModel.catalog.pages.count) pages", context: "System")

            // Delay the start of the templates download so the window can be ready faster
            try await Task.sleep(nanoseconds: 200_000_000)

            logger.verbose("Loading template catalog from server", context: "System")

            let templatesUrl = URL(string: "https://vero.andydragon.com/static/data/templates.json")!
            let templatesCatalog = try await URLSession.shared.decode(TemplateCatalog.self, from: templatesUrl)
            viewModel.catalog.templatesCatalog = ObservableTemplateCatalog(
                pages: templatesCatalog.pages.map({ templatePage in
                    ObservableTemplatePage(name: templatePage.name, templates: templatePage.templates.map({ ObservableTemplate(template: $0) }))
                }),
                specialTemplates: templatesCatalog.specialTemplates.map({ ObservableTemplate(template: $0) }))
            viewModel.catalog.waitingForTemplates = false

            logger.verbose("Loaded template catalog from server with \(viewModel.catalog.templatesCatalog.pages.count) page templates", context: "System")

#if STANDALONE
            do {
                // Delay the start of the disallowed list download so the window can be ready faster
                try await Task.sleep(nanoseconds: 100_000_000)

                appState.checkForUpdates()
            } catch {
                // do nothing, the version check is not critical
                debugPrint(error.localizedDescription)
            }
#endif
        } catch {
            logger.error("Failed to load page catalog or template catalog from server: \(error.localizedDescription)", context: "System")
            viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            viewModel.showToast(
                .fatal,
                "Failed to load pages",
                "The application requires the catalog to perform its operations: \(error.localizedDescription)\n\n" +
                "Click here to try again immediately or wait 15 seconds to automatically try again.",
                duration: 15,
                width: 720,
                buttonTitle: "Retry",
                onButtonTapped: {
                    logger.verbose("Retrying to load pages catalog after failure", context: "System")
                    DispatchQueue.main.async {
                        Task {
                            await loadPageCatalog()
                        }
                    }
                },
                onDismissed: {
                    logger.verbose("Retrying to load pages catalog after failure", context: "System")
                    DispatchQueue.main.async {
                        Task {
                            await loadPageCatalog()
                        }
                    }
                }
            )
        }
    }

    private func delayAndTerminate(_ longPause: Bool) {
        viewModel.ignoreDirty = true
        DispatchQueue.main.asyncAfter(
            deadline: .now() + (longPause ? (AdvancedToastStyle.success.duration + 0.4) : 0.2),
            execute: {
                NSApplication.shared.terminate(nil)
            })
    }

    private func generateReport() -> String? {
        if viewModel.isDirty {
            var lines = [String]()
            lines.append("REPORT OF CHANGES")
            lines.append("")

            for page in viewModel.catalog.pages {
                if page.isDirty {
                    // TODO andydragon : currently nothing can be dirty in a page?
                    logger.warning("Page cannot be dirty yet", context: "System")
                }
            }

            for templatePage in viewModel.catalog.templatesCatalog.pages {
                if templatePage.isDirty, let page = pageFromTemplatePage(templatePage) {
                    lines.append("-----------------")
                    lines.append("PAGE: '\(page.displayName)'")
                    let addedTemplates = templatePage.addedTemplates
                    for template in templatePage.templates {
                        if template.isDirty {
                            if template.isNewTemplate && addedTemplates.includes(template.name) {
                                logger.info("Template '\(template.name)' for page '\(page.displayName)' was added")
                                lines.append("")
                                lines.append("    ADD TEMPLATE: '\(template.name)'")
                                lines.append("    ---")
                                lines.append("        " + template.template.replacingOccurrences(of: "\n", with: "\n        "))
                                lines.append("    ---")
                            } else {
                                logger.info("Template '\(template.name)' for page '\(page.displayName)' was changed")
                                lines.append("")
                                lines.append("    MODIFY TEMPLATE: '\(template.name)'")
                                lines.append("    ---")
                                lines.append("        " + template.template.replacingOccurrences(of: "\n", with: "\n        "))
                                lines.append("    ---")
                            }
                        }
                    }
                    let removedTemplates = templatePage.removedTemplates
                    if removedTemplates.count > 0 {
                        for templateName in removedTemplates {
                            logger.info("Template '\(templateName)' for page '\(page.displayName)' was removed")
                            lines.append("")
                            lines.append("    REMOVE TEMPLATE: '\(templateName)'")
                        }
                    }
                }
            }

            lines.append("------------------")

            var text = ""
            for line in lines { text = text + line + "\n" }
            return text
        } else {
            viewModel.showInfoToast("There are no changes", "There are not changes to report")
            logger.verbose("There were no changes to report", context: "System")
            return nil
        }
    }

    private func navigateToPage(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(viewModel.catalog.pages, viewModel.selectedPage, direction)
        if change {
            if direction != .same {
                viewModel.selectedPage = newValue
            }
            selectedTemplate = nil
            viewModel.userLevel = viewModel.selectedPage?.hub == "snap" ? .snapHallOfFameMember : viewModel.selectedPage?.hub == "click" ? .clickPlatinumMember : .commonArtist
            viewModel.pageStaffLevel = .coadmin
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
            documentDirtyAlertDismissLable = "Quit"
            documentDirtyAlertConfirmation = "Are you sure you wish to quit?"
            documentDirtyAfterDismissAction = { longPause in
                delayAndTerminate(longPause)
            }
            documentDirtyAfterSaveAction = { longPause in
                delayAndTerminate(longPause)
            }
            viewModel.isShowingDocumentDirtyAlert.toggle()
        }
        return !viewModel.isDirty
    }
}
