//
//  Types.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI

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
         hubTag,
         featureScript,
         commentScript,
         originalPostScript,
         newMembershipScript
}

enum MembershipCase: String, CaseIterable, Identifiable, Codable {
    case none = "None",

         commonArtist = "Artist",
         commonMember = "Member",
         commonPlatinumMember = "Platinum Member",

         // snap
         snapVipMember = "VIP Member",
         snapVipGoldMember = "VIP Gold Member",
         snapEliteMember = "Elite Member",
         snapHallOfFameMember = "Hall of Fame Member",
         snapDiamondMember = "Diamond Member",
    
         // click
         clickBronzeMember = "Bronze Member",
         clickSilverMember = "Silver Member",
         clickGoldMember = "Gold Member"

    var id: Self { self }
    
    static func casesFor(hub: String?) -> [MembershipCase] {
        if hub == "snap" {
            return [
                .none,
                .commonArtist,
                .commonMember,
                .snapVipMember,
                .snapVipGoldMember,
                .commonPlatinumMember,
                .snapEliteMember,
                .snapHallOfFameMember,
                .snapDiamondMember
            ]
        }
        if hub == "click" {
            return [
                .none,
                .commonArtist,
                .commonMember,
                .clickBronzeMember,
                .clickSilverMember,
                .clickGoldMember,
                .commonPlatinumMember
            ]
        }
        return [
            .none,
            .commonArtist
        ]
    }
    
    static func caseValidFor(hub: String?, _ value: MembershipCase) -> Bool {
        if hub == "snap" {
            return [
                none,
                commonArtist,
                commonMember,
                snapVipMember,
                snapVipGoldMember,
                commonPlatinumMember,
                snapEliteMember,
                snapHallOfFameMember,
                snapDiamondMember
            ].contains(value)
        }
        if hub == "click" {
            return [
                none,
                commonArtist,
                commonMember,
                clickBronzeMember,
                clickSilverMember,
                clickGoldMember,
                commonPlatinumMember
            ].contains(value)
        }
        return [
            none,
            commonArtist
        ].contains(value)
    }
}

enum NewMembershipCase: String, CaseIterable, Identifiable, Codable {
    case none = "None",

         // common
         commonMember = "Member",
         
         // snap
         snapVipMember = "VIP Member",
    
         // click
         clickBronzeMember = "Bronze Member",
         clickSilverMember = "Silver Member",
         clickGoldMember = "Gold Member",
         clickPlatinumMember = "Platinum Member"
    
    var id: Self { self }
    
    static func casesFor(hub: String?) -> [NewMembershipCase] {
        if hub == "snap" {
            return [
                .none,
                .commonMember,
                .snapVipMember
            ]
        }
        if hub == "click" {
            return [
                .none,
                .commonMember,
                .clickBronzeMember,
                .clickSilverMember,
                .clickGoldMember,
                .clickPlatinumMember
            ]
        }
        return [
            .none
        ]
    }
    
    static func caseValidFor(hub: String?, _ value: NewMembershipCase) -> Bool {
        if hub == "snap" {
            return [
                none,
                commonMember,
                snapVipMember
            ].contains(value)
        } 
        if hub == "click" {
            return [
                none,
                commonMember,
                clickBronzeMember,
                clickSilverMember,
                clickGoldMember,
                clickPlatinumMember
            ].contains(value)
        }
        return [
            none
        ].contains(value)
    }
}

enum TagSourceCase: String, CaseIterable, Identifiable, Codable {
    case commonPageTag = "Page tag",
         
         // snap
         snapRawPageTag = "RAW page tag",
         snapCommunityTag = "Snap community tag",
         snapRawCommunityTag = "RAW community tag",
         snapMembershipTag = "Snap membership tag",
         
         // click
         clickCommunityTag = "Click community tag",
         clickHubTag = "Click hub tag"
    
    var id: Self { self }
    
    static func casesFor(hub: String?) -> [TagSourceCase] {
        if hub == "snap" {
            return [
                .commonPageTag,
                .snapRawPageTag,
                .snapCommunityTag,
                .snapRawCommunityTag,
                .snapMembershipTag
            ]
        }
        if hub == "click" {
            return [
                .commonPageTag,
                .clickCommunityTag,
                .clickHubTag
            ]
        }
        return [
            .commonPageTag
        ]
    }
    
    static func caseValidFor(hub: String?, _ value: TagSourceCase) -> Bool {
        if hub == "snap" {
            return [
                commonPageTag,
                snapRawPageTag,
                snapCommunityTag,
                snapRawCommunityTag,
                snapMembershipTag
            ].contains(value)
        }
        if hub == "click" {
            return [
                commonPageTag,
                clickCommunityTag,
                clickHubTag
            ].contains(value)
        }
        return [
            commonPageTag
        ].contains(value)
    }
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

struct ScriptsCatalog: Codable {
    var hubs: [String: [Page]]
}

struct Page: Codable {
    var id: String { self.name }
    let name: String
    let pageName: String?
    let hashTag: String?
}

struct LoadedPage: Codable, Identifiable {
    var id: String {
        if self.hub.isEmpty {
            return self.name
        }
        return "\(self.hub):\(self.name)"
    }
    let hub: String
    let name: String
    let pageName: String?
    let hashTag: String?
    var displayName: String {
        if hub == "other" {
            return name
        }
        return "\(hub)_\(name)"
    }

    static func from(hub: String, page: Page) -> LoadedPage {
        return LoadedPage(hub: hub, name: page.name, pageName: page.pageName, hashTag: page.hashTag)
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

enum ToastDuration: Int {
    case disabled = 0,
         short = 3,
         medium = 10,
         long = 20
}

struct CodableFeatureUser: Codable {
    var page: String
    var userName: String
    var userAlias: String
    var userLevel: MembershipCase
    var tagSource: TagSourceCase
    var firstFeature: Bool
    var newLevel: NewMembershipCase
    
    init() {
        page = ""
        userName = ""
        userAlias = ""
        userLevel = MembershipCase.none
        tagSource = TagSourceCase.commonPageTag
        firstFeature = false
        newLevel = NewMembershipCase.none
    }

    init(json: Data) {
        self.init()
        do {
            let decoder = JSONDecoder()
            let featureUser = try decoder.decode(CodableFeatureUser.self, from: json)
            self.page = featureUser.page
            self.userName = featureUser.userName
            self.userAlias = featureUser.userAlias
            self.userLevel = featureUser.userLevel
            self.tagSource = featureUser.tagSource
            self.firstFeature = featureUser.firstFeature
            self.newLevel = featureUser.newLevel
        } catch {
            debugPrint(error)
        }
    }
}
