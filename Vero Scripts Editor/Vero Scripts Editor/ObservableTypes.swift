//
//  ObservableTypes.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-12-17.
//

import SwiftUI

@Observable
class ObservableCatalog: Identifiable, Hashable {
    var id = UUID()
    var waitingForPages = true
    var pages = [ObservablePage]()
    var waitingForTemplates = true
    var templatesCatalog = ObservableTemplateCatalog(pages: [], specialTemplates: [])
    var waitingForDisallowList = true
    var disallowList = [String: [String]]()

    static func == (lhs: ObservableCatalog, rhs: ObservableCatalog) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Observable
class ObservableTemplateCatalog: Identifiable, Hashable {
    var id = UUID()
    var pages: [ObservableTemplatePage]
    var specialTemplates: [ObservableTemplate]

    init(pages: [ObservableTemplatePage], specialTemplates: [ObservableTemplate]) {
        self.pages = pages
        self.specialTemplates = specialTemplates
    }

    static func == (lhs: ObservableTemplateCatalog, rhs: ObservableTemplateCatalog) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Observable
class ObservableTemplatePage: Identifiable, Hashable {
    var id = UUID()
    var pageId: String { self.name }
    let name: String
    var templates: [ObservableTemplate]

    init(name: String, templates: [ObservableTemplate]) {
        self.name = name
        self.templates = templates
    }

    static func == (lhs: ObservableTemplatePage, rhs: ObservableTemplatePage) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Observable
class ObservablePage: Identifiable, Hashable {
    var id = UUID()
    var hub: String
    var name: String
    var pageName: String?
    var title: String?
    var hashTag: String?
    var displayName: String {
        if hub == "other" {
            return name
        }
        return "\(hub)_\(name)"
    }
    var displayTitle: String {
        return title ?? "\(hub) \(name)"
    }
    var hashTags: [String] {
        if hub == "snap" {
            if let basePageName = pageName {
                if basePageName != name {
                    return [hashTag ?? "#snap_\(name)", "#raw_\(name)", "#snap_\(basePageName)", "#raw_\(basePageName)"]
                }
            }
            return [hashTag ?? "#snap_\(name)", "#raw_\(name)"]
        } else if hub == "click" {
            return [hashTag ?? "#click_\(name)"]
        } else {
            return [hashTag ?? name]
        }
    }
    var pageId: String {
        if self.hub.isEmpty {
            return self.name
        }
        return "\(self.hub):\(self.name)"
    }

    init(hub: String, page: Page) {
        self.hub = hub
        self.name = page.name
        self.pageName = page.pageName
        self.title = page.title
        self.hashTag = page.hashTag
    }

    private init() {
        hub = ""
        name = ""
        pageName = nil
        title = nil
        hashTag = nil
    }

    static let dummy = ObservablePage()

    static func == (lhs: ObservablePage, rhs: ObservablePage) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Observable
class ObservableTemplate: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var template: String

    init(template: Template) {
        self.name = template.name
        self.template = template.template
    }

    init(name: String, template: String) {
        self.name = name
        self.template = template
    }

    private init() {
        name = ""
        template = ""
    }

    static func == (lhs: ObservableTemplate, rhs: ObservableTemplate) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
