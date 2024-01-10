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

final class PlaceholderValue: ObservableObject {
    @Published var Value = ""
}

final class PlaceholderList: ObservableObject {
    @Published var PlaceholderDict = [String: PlaceholderValue]()
}

struct PlaceholderView: View {
    let Element: [String: PlaceholderValue].Element
    var EditorName = ""
    @State var EditorValue = ""
    
    init(_ element: [String: PlaceholderValue].Element) {
        Element = element
        let start = element.key.index(element.key.startIndex, offsetBy: 2)
        let end = element.key.index(element.key.endIndex, offsetBy: -3)
        EditorName = String(element.key[start...end]);
        EditorValue = element.value.Value
    }
    
    var body: some View {
        if #available(macOS 13.0, *) {
            HStack {
                Text(EditorName)
                    .frame(minWidth: 200)
                TextField(
                    "leave blade to remove placeholder",
                    text: $EditorValue.onChange(editorValueChanged)
                )
                .frame(minWidth: 320)
                .padding(.all, 2)
#if os(iOS)
                .textInputAutocapitalization(.never)
#endif
                Spacer()
                    .background(Color.yellow)
            }
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
        } else {
            HStack {
                Text(Element.key)
                    .frame(minWidth: 200)
                TextField(
                    "leave blade to remove placeholder",
                    text: $EditorValue.onChange(editorValueChanged)
                )
                .frame(minWidth: 320)
                .padding(.all, 2)
#if os(iOS)
                .textInputAutocapitalization(.never)
#endif
                Spacer()
                    .background(Color.yellow)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    func editorValueChanged(to: String) {
        Element.value.Value = EditorValue
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
    @State var ShowingPopup = false
    @State var WaitingForCatalog: Bool = true
    @State var HubsCatalog = HubCatalog(hubs: [])
    @ObservedObject var Placeholders = PlaceholderList()
    @State var ScriptWithPlaceholdersUntouched = ""
    @State var ScriptWithPlaceholders = ""
    @State var lastMembership = MembershipCase.none
    @State var lastUserName = ""
    @State var lastYourName = ""
    @State var lastPage = ""
    @State var lastPageName = ""
    @State var lastPageStaffLevel = StaffLevelCase.mod

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
                        ScriptWithPlaceholders = FeatureScript
                        ScriptWithPlaceholdersUntouched = FeatureScript
                        Placeholders.PlaceholderDict.forEach({ placeholder in
                            ScriptWithPlaceholders = ScriptWithPlaceholders.replacingOccurrences(of: placeholder.key, with: placeholder.value.Value)
                        })
                        if !checkForPlaceholders(scripts: [ScriptWithPlaceholders, CommentScript, OriginalPostScript]) {
#if os(iOS)
                            UIPasteboard.general.string = ScriptWithPlaceholders
#else
                            let pasteBoard = NSPasteboard.general
                            pasteBoard.clearContents()
                            pasteBoard.writeObjects([ScriptWithPlaceholders as NSString])
#endif
                        }
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
                        ScriptWithPlaceholders = CommentScript
                        ScriptWithPlaceholdersUntouched = CommentScript
                        Placeholders.PlaceholderDict.forEach({ placeholder in
                            ScriptWithPlaceholders = ScriptWithPlaceholders.replacingOccurrences(of: placeholder.key, with: placeholder.value.Value)
                        })
                        if !checkForPlaceholders(scripts: [FeatureScript, ScriptWithPlaceholders, OriginalPostScript]) {
#if os(iOS)
                            UIPasteboard.general.string = ScriptWithPlaceholders
#else
                            let pasteBoard = NSPasteboard.general
                            pasteBoard.clearContents()
                            pasteBoard.writeObjects([ScriptWithPlaceholders as NSString])
#endif
                        }
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
                        ScriptWithPlaceholders = OriginalPostScript
                        ScriptWithPlaceholdersUntouched = OriginalPostScript
                        Placeholders.PlaceholderDict.forEach({ placeholder in
                            ScriptWithPlaceholders = ScriptWithPlaceholders.replacingOccurrences(of: placeholder.key, with: placeholder.value.Value)
                        })
                        if !checkForPlaceholders(scripts: [FeatureScript, CommentScript, ScriptWithPlaceholders]) {
#if os(iOS)
                            UIPasteboard.general.string = ScriptWithPlaceholders
#else
                            let pasteBoard = NSPasteboard.general
                            pasteBoard.clearContents()
                            pasteBoard.writeObjects([ScriptWithPlaceholders as NSString])
#endif
                        }
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
        .popover(isPresented: $ShowingPopup) {
            ZStack {
                VStack {
                    Text("There are manual placeholders that need to be filled out:")
                    List() {
                        ForEach(Placeholders.PlaceholderDict.sorted(by: { entry1, entry2 in entry1.key < entry2.key}), id: \.key) { entry in
                            PlaceholderView(entry)
                        }
                    }
                    .listStyle(.plain)
                    .frame(width: .infinity)
                    HStack {
                        Button(action: {
                            Placeholders.PlaceholderDict.forEach({ placeholder in
                                ScriptWithPlaceholders = ScriptWithPlaceholders.replacingOccurrences(of: placeholder.key, with: placeholder.value.Value)
                            })
#if os(iOS)
                            UIPasteboard.general.string = ScriptWithPlaceholders
#else
                            let pasteBoard = NSPasteboard.general
                            pasteBoard.clearContents()
                            pasteBoard.writeObjects([ScriptWithPlaceholders as NSString])
#endif
                            ShowingPopup.toggle()
                        }, label: {
                            Text("Copy")
                                .padding(.horizontal, 20)
                        })
                        Button(action: {
#if os(iOS)
                            UIPasteboard.general.string = ScriptWithPlaceholdersUntouched
#else
                            let pasteBoard = NSPasteboard.general
                            pasteBoard.clearContents()
                            pasteBoard.writeObjects([ScriptWithPlaceholdersUntouched as NSString])
#endif
                            ShowingPopup.toggle()
                        }, label: {
                            Text("Copy with Placeholders Unfilled")
                                .padding(.horizontal, 20)
                        })
                    }
                }
            }
            .frame(width: 600, height: 400)
            .padding()
        }
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
        if value != lastMembership {
            Placeholders.PlaceholderDict.removeAll()
            updateScripts()
            lastMembership = value
        }
    }

    func userNameChanged(to value: String) {
        if value != lastUserName {
            Placeholders.PlaceholderDict.removeAll()
            updateScripts()
            updateNewMembershipScripts()
            lastUserName = value
        }
    }

    func yourNameChanged(to value: String) {
        if value != lastYourName {
            Placeholders.PlaceholderDict.removeAll()
            UserDefaults.standard.set(YourName, forKey: "YourName")
            updateScripts()
            lastYourName = value
        }
    }

    func pageChanged(to value: String) {
        if value != lastPage {
            Placeholders.PlaceholderDict.removeAll()
            UserDefaults.standard.set(Page, forKey: "Page")
            updateScripts()
            lastPage = value
        }
    }

    func pageNameChanged(to value: String) {
        if value != lastPageName {
            Placeholders.PlaceholderDict.removeAll()
            UserDefaults.standard.set(PageName, forKey: "PageName")
            updateScripts()
            lastPageName = value
        }
    }
    
    func pageStaffLevelChanged(to value: StaffLevelCase) {
        if value != lastPageStaffLevel {
            Placeholders.PlaceholderDict.removeAll()
            UserDefaults.standard.set(PageStaffLevel.rawValue, forKey: "StaffLevel")
            updateScripts()
            lastPageStaffLevel = value
        }
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
    
    func checkForPlaceholders(scripts: [String]) -> Bool {
        var placeholders: [String] = [];
        scripts.forEach({ script in placeholders.append(contentsOf: matches(of: "\\[\\[([^\\]]*)\\]\\]", in: script))})
        if placeholders.count != 0 {
            var needEditor: Bool = false
            for placeholder in placeholders {
                let placeholderEntry = Placeholders.PlaceholderDict[placeholder]
                if placeholderEntry == nil {
                    needEditor = true
                    Placeholders.PlaceholderDict[placeholder] = PlaceholderValue()
                }
            }
            if needEditor && !ShowingPopup {
                ShowingPopup.toggle()
                return true
            }
        }
        return false
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
