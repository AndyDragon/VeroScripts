//
//  Types.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI

enum MembershipCase: String, CaseIterable, Identifiable, Codable {
    case none = "None"

    case commonArtist = "Artist"
    case commonMember = "Member"
    case commonPlatinumMember = "Platinum Member"

    // snap
    case snapVipMember = "VIP Member"
    case snapVipGoldMember = "VIP Gold Member"
    case snapEliteMember = "Elite Member"
    case snapHallOfFameMember = "Hall of Fame Member"
    case snapDiamondMember = "Diamond Member"

    // click
    case clickBronzeMember = "Bronze Member"
    case clickSilverMember = "Silver Member"
    case clickGoldMember = "Gold Member"

    var id: Self { self }

    static func allCasesSorted() -> [MembershipCase] {
        return [
            .none,
            .commonArtist,
            .commonMember,
            .snapVipMember,
            .snapVipGoldMember,
            .clickBronzeMember,
            .clickSilverMember,
            .clickGoldMember,
            .commonPlatinumMember,
            .snapEliteMember,
            .snapHallOfFameMember,
            .snapDiamondMember,
        ]
    }

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
                .snapDiamondMember,
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
                .commonPlatinumMember,
            ]
        }
        return [
            .none,
            .commonArtist,
        ]
    }

    static func caseValidFor(hub: String?, _ value: MembershipCase) -> Bool {
        return casesFor(hub: hub).contains(value)
    }

    func scriptMembershipStringForHub(hub: String?) -> String {
        (hub == "snap" && self != .commonArtist && self != .none) ? "Snap \(rawValue)"
            : (hub == "click" && self != .commonArtist && self != .none) ? "Click \(rawValue)"
            : rawValue
    }
}

extension MembershipCase {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedValue = try container.decode(String.self)
        if decodedValue.hasPrefix("Click ") {
            let rawValueWithoutPrefix = String(decodedValue[decodedValue.index(decodedValue.startIndex, offsetBy: "Click ".count)...])
            self = MembershipCase(rawValue: rawValueWithoutPrefix) ?? .none
        } else if decodedValue.hasPrefix("Snap ") {
            let rawValueWithoutPrefix = String(decodedValue[decodedValue.index(decodedValue.startIndex, offsetBy: "Snap ".count)...])
            self = MembershipCase(rawValue: rawValueWithoutPrefix) ?? .none
        } else {
            self = MembershipCase(rawValue: decodedValue) ?? .none
        }
    }
}

enum TagSourceCase: String, CaseIterable, Identifiable, Codable {
    case commonPageTag = "Page tag"

    // snap
    case snapRawPageTag = "RAW page tag"
    case snapCommunityTag = "Snap community tag"
    case snapRawCommunityTag = "RAW community tag"
    case snapMembershipTag = "Snap membership tag"

    // click
    case clickCommunityTag = "Click community tag"
    case clickHubTag = "Click hub tag"

    var id: Self { self }

    static func casesFor(hub: String?) -> [TagSourceCase] {
        if hub == "snap" {
            return [
                .commonPageTag,
                .snapRawPageTag,
                .snapCommunityTag,
                .snapRawCommunityTag,
                .snapMembershipTag,
            ]
        }
        if hub == "click" {
            return [
                .commonPageTag,
                .clickCommunityTag,
                .clickHubTag,
            ]
        }
        return [
            .commonPageTag,
        ]
    }

    static func caseValidFor(hub: String?, _ value: TagSourceCase) -> Bool {
        return casesFor(hub: hub).contains(value)
    }
}

enum StaffLevelCase: String, CaseIterable, Identifiable, Codable {
    case mod = "Mod"
    case coadmin = "Co-Admin"
    case admin = "Admin"

    // snap
    case snapGuestMod = "Guest moderator"

    var id: Self { self }

    static func casesFor(hub: String?) -> [StaffLevelCase] {
        if hub == "snap" {
            return [
                .mod,
                .coadmin,
                .admin,
                .snapGuestMod,
            ]
        }
        if hub == "click" {
            return [
                .mod,
                .coadmin,
                .admin,
            ]
        }
        return [
            .mod,
            .coadmin,
            .admin,
        ]
    }

    static func caseValidFor(hub: String?, _ value: StaffLevelCase) -> Bool {
        return casesFor(hub: hub).contains(value)
    }

    var shortString: String {
        if self == .snapGuestMod {
            return "Guest"
        }
        return rawValue
    }
}

enum PlaceholderSheetCase {
    case featureScript
    case commentScript
    case originalPostScript
}

enum NewMembershipCase: String, CaseIterable, Identifiable, Codable {
    case none = "None"

    // snap
    case snapMemberFeature = "Member (feature comment)"
    case snapMemberOriginalPost = "Member (original post comment)"
    case snapVipMemberFeature = "VIP Member (feature comment)"
    case snapVipMemberOriginalPost = "VIP Member (original post comment)"

    // click
    case clickMember = "Member"
    case clickBronzeMember = "Bronze Member"
    case clickSilverMember = "Silver Member"
    case clickGoldMember = "Gold Member"
    case clickPlatinumMember = "Platinum Member"

    var id: Self { self }

    static func casesFor(hub: String?) -> [NewMembershipCase] {
        if hub == "snap" {
            return [
                .none,
                .snapMemberFeature,
                .snapMemberOriginalPost,
                .snapVipMemberFeature,
                .snapVipMemberOriginalPost,
            ]
        }
        if hub == "click" {
            return [
                .none,
                .clickMember,
                .clickBronzeMember,
                .clickSilverMember,
                .clickGoldMember,
                .clickPlatinumMember,
            ]
        }
        return [
            .none,
        ]
    }

    static func scriptFor(hub: String?, _ value: NewMembershipCase) -> String {
        if hub == "snap" {
            switch value {
            case .snapMemberFeature:
                return "snap:member feature"
            case .snapMemberOriginalPost:
                return "snap:member original post"
            case .snapVipMemberFeature:
                return "snap:vip member feature"
            case .snapVipMemberOriginalPost:
                return "snap:vip member original post"
            default:
                return ""
            }
        } else if hub == "click" {
            return "\(hub ?? ""):\(value.rawValue.replacingOccurrences(of: " ", with: "_").lowercased())"
        }
        return ""
    }

    static func caseValidFor(hub: String?, _ value: NewMembershipCase) -> Bool {
        return casesFor(hub: hub).contains(value)
    }

    func scriptNewMembershipStringForHub(hub: String?) -> String {
        (hub == "snap" && self != .none) ? "Snap \(rawValue)"
            : (hub == "click" && self != .none) ? "Click \(rawValue)"
            : rawValue
    }
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

struct ScriptsCatalog: Codable {
    var hubs: [String: [Page]]
}

struct Page: Codable {
    var id: String { name }
    let name: String
    let pageName: String?
    let title: String?
    let hashTag: String?
}

struct LoadedPage: Codable, Identifiable, Hashable {
    var id: String {
        if self.hub.isEmpty {
            return self.name
        }
        return "\(self.hub):\(self.name)"
    }
    let hub: String
    let name: String
    let pageName: String?
    let title: String?
    let hashTag: String?
    var displayName: String {
        if hub == "other" {
            return name
        }
        return "\(hub)_\(name)"
    }

    static func from(hub: String, page: Page) -> LoadedPage {
        return LoadedPage(hub: hub, name: page.name, pageName: page.pageName, title: page.title, hashTag: page.hashTag)
    }
}

struct TemplateCatalog: Codable {
    let pages: [TemplatePage]
    let specialTemplates: [Template]
}

struct TemplatePage: Codable, Identifiable {
    var id: String { name }
    let name: String
    let templates: [Template]
}

struct HubCatalog: Codable {
    let hubs: [Hub]
}

struct Hub: Codable, Identifiable {
    var id: String { name }
    let name: String
    let templates: [Template]
}

struct Template: Codable, Identifiable {
    var id: String { name }
    let name: String
    let template: String
}
