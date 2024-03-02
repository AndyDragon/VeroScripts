//
//  Types.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-02-10.
//

enum FocusedField: Hashable {
    case userName,
         level,
         yourName,
         yourFirstName,
         page,
         pageName,
         staffLevel,
         firstFeature,
         rawTag,
         communityTag,
         featureScript,
         commentScript,
         originalPostScript
}

enum MembershipCase: String, CaseIterable, Identifiable {
    case none = "None",
         artist = "Artist",
         member = "Member",
         vipMember = "VIP Member",
         goldMember = "VIP Gold Member",
         platinumMember = "Platinum Member",
         eliteMember = "Elite Member",
         hallOfFameMember = "Hall of Fame Member",
         diamondMember = "Diamond Member"
    var id: Self { self }
}

enum ClickMembershipCase: String, CaseIterable, Identifiable {
    case none = "None",
         artist = "Artist",
         member = "Member",
         bronzeMember = "Bronze Member",
         silverMember = "Silver Member",
         goldMember = "Gold Member",
         platinumMember = "Platinum Member"
    var id: Self { self }
}

enum NewMembershipCase: String, CaseIterable, Identifiable {
    case none = "None",
         member = "Member",
         vipMember = "VIP Member"
    var id: Self { self }
}

enum StaffLevelCase: String, CaseIterable, Identifiable {
    case mod = "Mod",
         coadmin = "Co-Admin",
         admin = "Admin"
    var id: Self { self }
}

enum PlaceholderSheetCase {
    case featureScript,
         commentScript,
         originalPostScript
}

struct PageCatalog: Codable {
    var pages: [Page]
    var hubs: [String: [HubPage]]?
}

struct Page: Codable {
    var id: String { self.name }
    let name: String
    let pageName: String?
}

struct HubPage: Codable {
    var id: String { self.name }
    let name: String
    let pageName: String?
    let users: [String]?
}

struct LoadedPage: Codable, Identifiable {
    var id: String {
        if let hub = self.hubName {
            return "\(hub):\(self.name)"
        }
        return self.name
    }
    let name: String
    let pageName: String?
    let hubName: String?
    var displayName: String {
        if let hub = hubName {
            return "\(hub)_\(name)"
        }
        return name;
    }

    static func from(page: Page) -> LoadedPage {
        return LoadedPage(name: page.name, pageName: page.pageName, hubName: nil)
    }
    
    static func from(hubPage: HubPage, with name: String) -> LoadedPage {
        return LoadedPage(name: hubPage.name, pageName: hubPage.pageName, hubName: name)
    }
}

struct TemplateCatalog: Codable {
    let pages: [TemplatePage]
    let specialTemplates: [Template]
}

struct TemplatePage: Codable, Identifiable {
    var id: String { self.name }
    let name: String
    let templates: [Template]
}

struct HubCatalog: Codable {
    let hubs: [Hub]
}

struct Hub: Codable, Identifiable {
    var id: String { self.name }
    let name: String
    let templates: [Template]
}

struct Template: Codable, Identifiable {
    var id: String { self.name }
    let name: String
    let template: String
}

struct VersionManifest: Codable {
    let macOS: VersionEntry
    let windows: VersionEntry
}

struct VersionEntry: Codable {
    let current: String
    let link: String
    let vital: Bool
}

enum ToastDuration: Int {
    case disabled = 0,
         short = 3,
         medium = 10,
         long = 20
}

enum Theme: String, CaseIterable, Identifiable {
    case notSet,
         systemDark = "System dark",
         darkSubtleGray = "Dark subtle gray",
         darkBlue = "Dark blue",
         darkGreen = "Dark green",
         darkRed = "Dark red",
         darkViolet = "Dark violet",
         systemLight = "System light",
         lightSubtleGray = "Light subtle gray",
         lightBlue = "Light blue",
         lightGreen = "Light green",
         lightRed = "Light red",
         lightViolet = "Light violet"
    var id: Self { self }
}
