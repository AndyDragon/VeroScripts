//
//  ContentView.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-01-03.
//

import SwiftUI

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

enum NewMembershipCase: String, CaseIterable, Identifiable {
    case none = "None",
         member = "Member",
         vipMember = "VIP Member"
    var id: Self { self }
}

enum StaffLevelCase: String, CaseIterable, Identifiable {
    case mod = "Mod",
         admin = "Admin"
    var id: Self { self }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

func matches(of regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
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

extension URLSession {
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from url: URL,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .deferredToData,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
    ) async throws  -> T {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        let (data, _) = try await data(for: request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dataDecodingStrategy = dataDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy

        let decoded = try decoder.decode(T.self, from: data)
        return decoded
    }
}

struct ContentView: View {
    @State var Membership: MembershipCase = MembershipCase.none
    @State var UserName: String = ""
    @State var YourName: String = UserDefaults.standard.string(forKey: "YourName") ?? ""
    @State var Page: String = UserDefaults.standard.string(forKey: "Page") ?? "default"
    @State var PageName: String = UserDefaults.standard.string(forKey: "PageName") ?? ""
    @State var PageStaffLevel: StaffLevelCase = StaffLevelCase(rawValue: UserDefaults.standard.string(forKey: "StaffLevel") ?? StaffLevelCase.mod.rawValue) ?? StaffLevelCase.mod
    @State var FirstForPage: Bool = false
    @State var CommunityTag: Bool = false
    @State var FeatureScript: String = ""
    @State var CommentScript: String = ""
    @State var OriginalPostScript: String = ""
    @State var NewMembership: NewMembershipCase = NewMembershipCase.none
    @State var NewMembershipScript: String = ""
    @State var ShowingAlert = false
    @State var AlertTitle: String = ""
    @State var AlertMessage: String = ""
    @State var TerminalAlert = false
    @State var WaitingForCatalog: Bool = true
    @State var HubsCatalog = HubCatalog(hubs: [])
    
    @Environment(\.colorScheme) var ColorScheme

    var body: some View {
        VStack {
            Group {
                // User name editor
                HStack {
                    Text("User: ")
#if os(iOS)
                        .frame(width: 60, alignment: .leading)
#else
                        .frame(width: 38, alignment: .leading)
#endif
                    TextField(
                        "Enter user name",
                        text: $UserName.onChange(userNameChanged)
                    )
#if os(iOS)
                    .textInputAutocapitalization(.never)
#endif
                }
                
                // User level picker
                HStack {
#if os(iOS)
                    Text("Level: ")
                        .frame(width: 60, alignment: .leading)
#endif
                    Picker("Level: ", selection: $Membership.onChange(membershipChanged)) {
                        ForEach(MembershipCase.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .focusable()
                    Spacer()
                }

                // Your name editor
                HStack {
                    Text("You: ")
#if os(iOS)
                        .frame(width: 60, alignment: .leading)
#else
                        .frame(width: 38, alignment: .leading)
#endif
                    TextField(
                        "Enter your name:",
                        text: $YourName.onChange(yourNameChanged)
                    )
#if os(iOS)
                    .textInputAutocapitalization(.never)
#endif
                }
                
                // Page name editor
                HStack {
#if os(iOS)
                    Text("Page: ")
#endif
                    Picker("Page: ", selection: $Page.onChange(pageChanged)) {
                        ForEach(HubsCatalog.hubs) { hub in
                            Text(hub.name).tag(hub.name)
                        }
                    }
                    .focusable()
                    TextField(
                        "Enter page name",
                        text: $PageName.onChange(pageNameChanged)
                    )
                    .disabled(Page != "default")
                    .focusable(Page == "default")
#if os(iOS)
                    .textInputAutocapitalization(.never)
#endif
#if os(iOS)
                    Text("Page staff level: ")
#endif
                    Picker("Page staff level: ", selection: $PageStaffLevel.onChange(pageStaffLevelChanged)) {
                        ForEach(StaffLevelCase.allCases) { staffLevelCase in
                            Text(staffLevelCase.rawValue).tag(staffLevelCase)
                        }
                    }
                    .focusable()
#if !os(iOS)
                    Toggle(isOn: $FirstForPage.onChange(firstForPageChanged)) {
                        Text("First feature on page")
                    }
                    .focusable()
                    Toggle(isOn: $CommunityTag.onChange(communityTagChanged)) {
                        Text("From community tag")
                    }
                    .focusable()
#else
                    Spacer()
#endif
                }
            }
            
#if os(iOS)
            HStack {
                Toggle(isOn: $FirstForPage.onChange(firstForPageChanged)) {
                    Text("First feature on page")
                }
                .focusable()
                Toggle(isOn: $CommunityTag.onChange(communityTagChanged)) {
                    Text("From community tag")
                }
                .focusable()
                Spacer()
            }
#endif
            
            Group {
                // Feature script output
                HStack {
                    Text("Feature script:")
                    Button(action: {
#if os(iOS)
                        UIPasteboard.general.string = FeatureScript
#else
                        let pasteBoard = NSPasteboard.general
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([FeatureScript as NSString])
#endif
                        checkForPlaceholders(in: FeatureScript)
                    }, label: {
                        Text("Copy")
                            .padding(.horizontal, 20)
                    })
                    Spacer()
                }
                .frame(alignment: .leading)
                TextEditor(text: $FeatureScript)
#if os(iOS)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .colorMultiply(Color(
                        red: ColorScheme == .dark ? 1.05 : 0.95,
                        green: ColorScheme == .dark ? 1.05 : 0.95,
                        blue: ColorScheme == .dark ? 1.05 : 0.95))
                    .border(.gray)
#else
                    .frame(minWidth: 400, maxWidth: .infinity, minHeight: 200)
#endif
                // Comment script output
                HStack {
                    Text("Comment script:")
                    Button(action: {
#if os(iOS)
                        UIPasteboard.general.string = CommentScript
#else
                        let pasteBoard = NSPasteboard.general
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([CommentScript as NSString])
#endif
                        checkForPlaceholders(in: CommentScript)
                    }, label: {
                        Text("Copy")
                            .padding(.horizontal, 20)
                    })
                    Spacer()
                }
                .frame(alignment: .leading)
                TextEditor(text: $CommentScript)
#if os(iOS)
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 80)
                    .colorMultiply(Color(
                        red: ColorScheme == .dark ? 1.05 : 0.95,
                        green: ColorScheme == .dark ? 1.05 : 0.95,
                        blue: ColorScheme == .dark ? 1.05 : 0.95))
                    .border(.gray)
#else
                    .frame(minWidth: 200, maxWidth: .infinity, minHeight: 80, maxHeight: 160)
#endif
                
                // Original post script output
                HStack {
                    Text("Original post script:")
                    Button(action: {
#if os(iOS)
                        UIPasteboard.general.string = OriginalPostScript
#else
                        let pasteBoard = NSPasteboard.general
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([OriginalPostScript as NSString])
#endif
                        checkForPlaceholders(in: OriginalPostScript)
                    }, label: {
                        Text("Copy")
                            .padding(.horizontal, 20)
                    })
                    Spacer()
                }
                .frame(alignment: .leading)
                TextEditor(text: $OriginalPostScript)
#if os(iOS)
                    .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 60)
                    .colorMultiply(Color(
                        red: ColorScheme == .dark ? 1.05 : 0.95,
                        green: ColorScheme == .dark ? 1.05 : 0.95,
                        blue: ColorScheme == .dark ? 1.05 : 0.95))
                    .border(.gray)
#else
                    .frame(minWidth: 200, maxWidth: .infinity, minHeight: 40, maxHeight: 80)
#endif
            }
            
            Group {
                // New membership picker and script output
                HStack {
#if os(iOS)
                    Text("New membership: ")
#endif
                    Picker("New membership: ", selection: $NewMembership.onChange(newMembershipChanged)) {
                        ForEach(NewMembershipCase.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    Button(action: {
#if os(iOS)
                        UIPasteboard.general.string = NewMembershipScript
#else
                        let pasteBoard = NSPasteboard.general
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([NewMembershipScript as NSString])
#endif
                        checkForPlaceholders(in: NewMembershipScript)
                    }, label: {
                        Text("Copy")
                            .padding(.horizontal, 20)
                    })
                    Spacer()
                }
                .frame(alignment: .leading)
                TextEditor(text: $NewMembershipScript)
#if os(iOS)
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 80)
                    .colorMultiply(Color(
                        red: ColorScheme == .dark ? 1.05 : 0.95,
                        green: ColorScheme == .dark ? 1.05 : 0.95,
                        blue: ColorScheme == .dark ? 1.05 : 0.95))
                    .border(.gray)
#else
                    .frame(minWidth: 200, maxWidth: .infinity, minHeight: 80, maxHeight: 160)
#endif
            }
        }
        .padding()
        .textFieldStyle(.roundedBorder)
        .alert(
            AlertTitle,
            isPresented: $ShowingAlert,
            actions: {
                Button("OK", action: {
                    if TerminalAlert {
#if os(iOS)
#else
                        NSApplication.shared.terminate(nil)
#endif
                    }
                })
            },
            message: {
                Text(AlertMessage)
            })
        .disabled(WaitingForCatalog)
        .task {
            do {
                let hubsUrl = URL(string: "https://andydragon.com/depot/VERO/hubs.json")!
                HubsCatalog = try await URLSession.shared.decode(HubCatalog.self, from: hubsUrl)
                WaitingForCatalog = false;
            } catch {
                AlertTitle = "Could not load the hubs catalog from the server"
                AlertMessage = "The application requires the catalog to perform its operations"
                TerminalAlert = true
                ShowingAlert = true
            }
        }
    }

    func membershipChanged(to value: MembershipCase) {
        updateScripts()
    }

    func userNameChanged(to value: String) {
        updateScripts()
        updateNewMembershipScripts()
    }

    func yourNameChanged(to value: String) {
        UserDefaults.standard.set(YourName, forKey: "YourName")
        updateScripts()
    }

    func pageChanged(to value: String) {
        UserDefaults.standard.set(Page, forKey: "Page")
        updateScripts()
    }

    func pageNameChanged(to value: String) {
        UserDefaults.standard.set(PageName, forKey: "PageName")
        updateScripts()
    }
    
    func pageStaffLevelChanged(to value: StaffLevelCase) {
        UserDefaults.standard.set(PageStaffLevel.rawValue, forKey: "StaffLevel")
        updateScripts()
    }
    
    func firstForPageChanged(to value: Bool) {
        updateScripts()
    }
    
    func communityTagChanged(to value: Bool) {
        updateScripts()
    }

    func newMembershipChanged(to value: NewMembershipCase) {
        updateNewMembershipScripts()
    }

    func checkForPlaceholders(in value: String) {
        let placeholders = matches(of: "\\[\\[([^\\]]*)\\]\\]", in: value)
        if placeholders.count != 0 {
            var placeholdersList = ""
            for placeholder in placeholders {
                placeholdersList += placeholder + "\n"
            }
            if !ShowingAlert {
                AlertTitle = "Remember to fill in the placeholders:"
                AlertMessage = placeholdersList
                ShowingAlert = true
            }
        }
    }
    
    func updateScripts() -> Void {
        if Membership == MembershipCase.none || UserName.isEmpty || YourName.isEmpty || (Page == "default" && PageName.isEmpty) {
            FeatureScript = ""
            OriginalPostScript = ""
            CommentScript = ""
        } else {
            let pageName = Page == "default" ? PageName : Page
            let featureScriptTemplate = getTemplateFromHubs(
                "feature",
                from: pageName,
                firstFeature: FirstForPage,
                communityTag: CommunityTag) ?? ""
            let commentScriptTemplate = getTemplateFromHubs(
                "comment",
                from: pageName,
                firstFeature: FirstForPage,
                communityTag: CommunityTag) ?? ""
            let originalPostScriptTemplate = getTemplateFromHubs(
                "original post",
                from: pageName,
                firstFeature: FirstForPage,
                communityTag: CommunityTag) ?? ""
            FeatureScript = featureScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: pageName)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: Membership.rawValue)
                .replacingOccurrences(of: "%%USERNAME%%", with: UserName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: YourName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: PageStaffLevel.rawValue)
            OriginalPostScript = originalPostScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: pageName)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: Membership.rawValue)
                .replacingOccurrences(of: "%%USERNAME%%", with: UserName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: YourName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: PageStaffLevel.rawValue)
            CommentScript = commentScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: pageName)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: Membership.rawValue)
                .replacingOccurrences(of: "%%USERNAME%%", with: UserName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: YourName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: PageStaffLevel.rawValue)
        }
    }
    
    func getTemplateFromHubs(_ templateName: String, from hubName: String, firstFeature: Bool, communityTag: Bool) -> String! {
        var template: Template!
        let defaultHub = HubsCatalog.hubs.first(where: { hub in hub.name == "default" });
        let hub = HubsCatalog.hubs.first(where: { hub in hub.name == hubName});
        if communityTag {
            template = hub?.templates.first(where: { template in template.name == "community " + templateName})
            if template == nil {
                template = defaultHub?.templates.first(where: { template in template.name == "community " + templateName})
            }
        } else if firstFeature {
            template = hub?.templates.first(where: { template in template.name == "first " + templateName})
            if template == nil {
                template = defaultHub?.templates.first(where: { template in template.name == "first " + templateName})
            }
        }
        if template == nil {
            template = hub?.templates.first(where: { template in template.name == templateName})
        }
        if template == nil {
            template = defaultHub?.templates.first(where: { template in template.name == templateName})
        }
        return template?.template
    }

    func updateNewMembershipScripts() -> Void {
        if NewMembership == NewMembershipCase.none || UserName == "" {
            NewMembershipScript = ""
        } else if NewMembership == NewMembershipCase.member {
            NewMembershipScript =
                "Congratulations @" + UserName + " on your 5th feature!\n" +
                "\n" +
                "I took the time to check the number of features you have with the SNAP Community and wanted to share with you that you are now a Member of the SNAP Community!\n" +
                "\n" +
                "That's an awesome achievement 👏🏼👏🏼💐💐💐💐💐💐.\n" +
                "\n" +
                "Please consider adding ✨ SNAP Community Member ✨ to your bio it will give you the chance to be featured in any raw page using only the membership tag.\n"
        } else if NewMembership == NewMembershipCase.vipMember {
            NewMembershipScript =
                "Congratulations @" + UserName + " on your 15th feature!\n" +
                "\n" +
                "I took the time to check the number of features you have with the SNAP Community and wanted to share that you are now a VIP Member of the SNAP Community!\n" +
                "\n" +
                "That's an awesome achievement 👏🏼👏🏼💐💐💐💐💐💐.\n" +
                "\n" +
                "Please consider adding ✨ SNAP VIP Member ✨ to your bio it will give you the chance to be featured in any raw page using only the membership tag."
        }
    }
}
