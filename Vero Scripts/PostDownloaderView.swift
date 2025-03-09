//
//  PostDownloaderView.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-11-22.
//

import Kingfisher
import SwiftSoup
import SwiftUI
import SwiftyBeaver

/// The `PostDownloaderView` provides a view which shows data from a user's post as well as their user profile bio.
///
/// If the post cannot be downloaded, the feature must be done directly from VERO instead. This usually happens when
/// the user's profile is marked as private.
///
struct PostDownloaderView: View {
    @Environment(\.openURL) private var openURL

    @Bindable private var viewModel: ContentView.ViewModel
    private var updateScripts: () -> Void
    @State private var focusedField: FocusState<FocusedField?>.Binding

    @State private var imageUrls: [URL] = []
    @State private var pageHashtagCheck = ""
    @State private var missingTag = false
    @State private var excludedHashtagCheck = ""
    @State private var hasExcludedHashtag = false
    @State private var excludedHashtags = ""
    @State private var postHashtags: [String] = []
    @State private var postLoaded = false
    @State private var profileLoaded = false
    @State private var description = ""
    @State private var userAlias = ""
    @State private var userName = ""
    @State private var logging: [(Color, String)] = []
    @State private var pageComments: [(String, String, Date?, String)] = [] // PageId, Comment, Date, PageName
    @State private var hubComments: [(String, String, Date?, String)] = [] // PageId, Comment, Date, PageName
    @State private var moreComments = false
    @State private var commentCount = 0
    @State private var likeCount = 0
    @State private var userProfileLink = ""
    @State private var userBio = ""

    private let languagePrefix = Locale.preferredLanguageCode
    private let mainLabelWidth: CGFloat = -128
    private let labelWidth: CGFloat = 108
    private let logger = SwiftyBeaver.self

    init(
        _ viewModel: ContentView.ViewModel,
        _ updateScripts: @escaping () -> Void,
        _ focusedField: FocusState<FocusedField?>.Binding
    ) {
        self.viewModel = viewModel
        self.updateScripts = updateScripts
        self.focusedField = focusedField
    }

    var body: some View {
        ZStack {
            Color.backgroundColor.edgesIgnoringSafeArea(.all)

            ScrollView(.vertical) {
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .center) {
                            // Page scope
                            PageScopeView()
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background {
                                    Rectangle()
                                        .foregroundStyle(Color.controlBackground)
                                        .cornerRadius(8)
                                        .opacity(0.5)
                                }

                            if profileLoaded {
                                // User alias, name and bio
                                ProfileView()
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        Rectangle()
                                            .foregroundStyle(Color.controlBackground)
                                            .cornerRadius(8)
                                            .opacity(0.5)
                                    }
                            }

                            if postLoaded {
                                // Tag check and description
                                TagCheckAndDescriptionView()
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        Rectangle()
                                            .foregroundStyle(Color.controlBackground)
                                            .cornerRadius(8)
                                            .opacity(0.5)
                                    }

                                // Page and hub comments
                                if !pageComments.isEmpty || !hubComments.isEmpty {
                                    PageAndHubCommentsView()
                                        .padding(12)
                                        .frame(maxWidth: .infinity)
                                        .background {
                                            Rectangle()
                                                .foregroundStyle(Color.controlBackground)
                                                .cornerRadius(8)
                                                .opacity(0.5)
                                        }
                                } else if moreComments {
                                    MoreCommentsView()
                                        .padding(12)
                                        .frame(maxWidth: .infinity)
                                        .background {
                                            Rectangle()
                                                .foregroundStyle(Color.controlBackground)
                                                .cornerRadius(8)
                                                .opacity(0.5)
                                        }
                                }

                                // Images
                                ImagesView()
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        Rectangle()
                                            .foregroundStyle(Color.controlBackground)
                                            .cornerRadius(8)
                                            .opacity(0.5)
                                    }
                            }

                            // Logging
                            LoggingView()
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background {
                                    Rectangle()
                                        .foregroundStyle(Color.controlBackground)
                                        .cornerRadius(8)
                                        .opacity(0.5)
                                }
                        }
                        .padding(10)
                    }
                    Spacer()
                }
                .padding()
            }
            .foregroundStyle(Color.label, Color.secondaryLabel)
            .toolbar {
                Button(action: {
                    viewModel.visibleView = .ScriptView
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                        Text("Close")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.label, Color.secondaryLabel)
                        Text(languagePrefix == "en" ? "    ⌘ `" : "    ⌘ ⌥ x")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray, Color.secondaryLabel)
                    }
                    .padding(4)
                }
                .keyboardShortcut(languagePrefix == "en" ? "`" : "x", modifiers: languagePrefix == "en" ? .command : [.command, .option])
                .disabled(viewModel.hasModalToasts)
            }
        }
        .frame(minWidth: 1024, minHeight: 600)
        .background(Color.backgroundColor)
        .onAppear {
            postLoaded = false
            pageHashtagCheck = ""
            missingTag = false
            excludedHashtagCheck = ""
            hasExcludedHashtag = false
            imageUrls = []
            logging = []
            userProfileLink = ""
            userBio = ""
            pageComments = []
            hubComments = []
            moreComments = false
            commentCount = 0
            likeCount = 0
            viewModel.showToast(.progress, "Loading", "Loading the post data from the server...")
            loadExcludedTagsForPage()
            Task.detached {
                await loadFeature()
            }
        }
    }

    // MARK: - sub views

    private func PageScopeView() -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    ValidationLabel("Page: ", labelWidth: -mainLabelWidth, validation: true, validColor: .green)
                    if let currentPage = viewModel.currentPage {
                        ValidationLabel(currentPage.displayTitle, validation: true, validColor: .accentColor)
                    }
                    Spacer()
                }
                .frame(height: 20)

                HStack(alignment: .center) {
                    ValidationLabel("Page tags: ", labelWidth: -mainLabelWidth, validation: true, validColor: .green)
                    if let currentPage = viewModel.currentPage {
                        ValidationLabel(currentPage.hashTags.joined(separator: ", "), validation: true, validColor: .accentColor)
                    }
                    Spacer()
                }
                .frame(height: 20)

                HStack(alignment: .center) {
                    ValidationLabel("Excluded hashtags: ", labelWidth: -mainLabelWidth, validation: true, validColor: .green)
                    HStack(alignment: .center) {
                        TextField(
                            "add excluded hashtags without the '#' separated by comma",
                            text: $excludedHashtags.onChange { _ in
                                storeExcludedTagsForPage()
                            }
                        )
                        .focused(focusedField, equals: .postUserName)
                    }
                    .autocorrectionDisabled(false)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.controlBackground.opacity(0.5))
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    .frame(maxWidth: 480)
                    Spacer()
                }
                .frame(height: 20)

                HStack(alignment: .center) {
                    ValidationLabel("Post URL: ", labelWidth: -mainLabelWidth, validation: viewModel.validatePostLink(value: viewModel.postLink ?? ""), validColor: .green)
                    ValidationLabel(viewModel.postLink ?? "", validation: true, validColor: .accentColor)

                    Spacer()

                    Button(action: {
                        logger.verbose("Tapped copy URL for post", context: "User")
                        copyToClipboard(viewModel.postLink!)
                        viewModel.showSuccessToast("Copied to clipboard", "Copied the post URL to the clipboard")
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "pencil.and.list.clipboard")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                            Text("Copy URL")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        logger.verbose("Pressed space on copy URL for post", context: "User")
                        copyToClipboard(viewModel.postLink!)
                        viewModel.showSuccessToast("Copied to clipboard", "Copied the post URL to the clipboard")
                        return .handled
                    }
                    .disabled(viewModel.postLink == nil)

                    Spacer()
                        .frame(width: 10)

                    Button(action: {
                        if let url = URL(string: viewModel.postLink!) {
                            logger.verbose("Tapped launch for post", context: "User")
                            openURL(url)
                        }
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "globe")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                            Text("Launch")
                        }
                    }
                    .disabled(viewModel.postLink == nil || viewModel.postLink!.isEmpty)
                    .focusable(viewModel.postLink != nil && !viewModel.postLink!.isEmpty)
                    .onKeyPress(.space) {
                        if let postLink = viewModel.postLink, let url = URL(string: postLink) {
                            logger.verbose("Pressed space on launch for post", context: "User")
                            openURL(url)
                        }
                        return .handled
                    }
                }
                .frame(height: 20)

                HStack(alignment: .center) {
                    ValidationLabel("User profile URL: ", labelWidth: -mainLabelWidth, validation: !userProfileLink.isEmpty, validColor: .green)
                    ValidationLabel(userProfileLink, validation: true, validColor: .accentColor)

                    Spacer()

                    Button(action: {
                        logger.verbose("Tapped copy URL for profile", context: "User")
                        copyToClipboard(userProfileLink)
                        viewModel.showSuccessToast("Copied to clipboard", "Copied the user profile URL to the clipboard")
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "pencil.and.list.clipboard")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                            Text("Copy URL")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        logger.verbose("Pressed space on copy URL for profile", context: "User")
                        copyToClipboard(userProfileLink)
                        viewModel.showSuccessToast("Copied to clipboard", "Copied the user profile URL to the clipboard")
                        return .handled
                    }

                    Spacer()
                        .frame(width: 10)

                    Button(action: {
                        if let url = URL(string: userProfileLink) {
                            logger.verbose("Tapped launch for profile", context: "User")
                            openURL(url)
                        }
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "globe")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                            Text("Launch")
                        }
                    }
                    .disabled(userProfileLink.isEmpty)
                    .focusable(!userProfileLink.isEmpty)
                    .onKeyPress(.space) {
                        if let url = URL(string: userProfileLink) {
                            logger.verbose("Pressed space on launch for profile", context: "User")
                            openURL(url)
                        }
                        return .handled
                    }
                }
                .frame(height: 20)
            }
            .frame(maxWidth: 1280)
        }
    }

    private func ProfileView() -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    ValidationLabel("User alias: ", labelWidth: -mainLabelWidth, validation: !userAlias.isEmpty, validColor: .green)
                    ValidationLabel(userAlias, validation: true, validColor: .accentColor)

                    Spacer()

                    ValidationLabel("User alias:", labelWidth: labelWidth, validation: viewModel.validateUserName(value: viewModel.userName))
                    HStack(alignment: .center) {
                        TextField(
                            "enter the user alias",
                            text: $viewModel.userName.onChange { value in
                                viewModel.userNameValidation = viewModel.validateUserName(value: viewModel.userName)
                                updateScripts()
                            }
                        )
                        .focused(focusedField, equals: .postUserAlias)
                    }
                    .autocorrectionDisabled(false)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.controlBackground.opacity(0.5))
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    .frame(maxWidth: 240)

                    Button(action: {
                        viewModel.userName = userAlias
                        viewModel.userNameValidation = viewModel.validateUserName(value: viewModel.userName)
                        updateScripts()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "pencil.line")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                            Text("Transfer")
                        }
                    }
                    .disabled(userAlias.isEmpty)
                    .focusable(!userAlias.isEmpty)
                    .onKeyPress(.space) {
                        if !userAlias.isEmpty {
                            viewModel.userName = userAlias
                            viewModel.userNameValidation = viewModel.validateUserName(value: viewModel.userName)
                            updateScripts()
                        }
                        return .handled
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 20)

                HStack(alignment: .center) {
                    ValidationLabel("User name: ", labelWidth: mainLabelWidth, validation: !userName.isEmpty, validColor: .green)
                    ValidationLabel(userName, validation: true, validColor: .accentColor)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 20)

                HStack(alignment: .center) {
                    ValidationLabel("User BIO:", validation: !userBio.isEmpty, validColor: .green)

                    Spacer()

                    ValidationLabel("User level:", labelWidth: labelWidth, validation: viewModel.validateMembership(value: viewModel.membership))
                    Picker(
                        "",
                        selection: $viewModel.membership.onChange { _ in
                            navigateToUserLevel(.same)
                        }
                    ) {
                        ForEach(MembershipCase.casesFor(hub: viewModel.currentPage?.hub ?? "")) { level in
                            Text(level.rawValue)
                                .tag(level)
                                .foregroundStyle(Color.secondaryLabel, Color.secondaryLabel)
                        }
                    }
                    .tint(Color.accentColor)
                    .accentColor(Color.accentColor)
                    .foregroundStyle(Color.accentColor, Color.label)
                    .focusable()
                    .focused(focusedField, equals: .postUserLevel)
                    .frame(maxWidth: 240)
                    .onKeyPress(phases: .down) { keyPress in
                        navigateToUserLevelWithArrows(keyPress)
                    }
                    .onKeyPress(characters: .alphanumerics) { keyPress in
                        navigateToUserLevelWithPrefix(keyPress)
                    }
                }
                .frame(maxWidth: .infinity)

                HStack(alignment: .top) {
                    ScrollView {
                        if #available(macOS 14.0, *) {
                            TextEditor(text: .constant(userBio))
                                .scrollIndicators(.never)
                                .focusable(false)
                                .frame(maxWidth: 620, maxHeight: .infinity, alignment: .leading)
                                .textEditorStyle(.plain)
                                .foregroundStyle(Color.label, Color.secondaryLabel)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                                .autocorrectionDisabled(false)
                                .disableAutocorrection(false)
                                .font(.system(size: 18, design: .serif))
                        } else {
                            TextEditor(text: .constant(userBio))
                                .scrollIndicators(.never)
                                .focusable(false)
                                .frame(maxWidth: 620, maxHeight: .infinity, alignment: .leading)
                                .foregroundStyle(Color.label, Color.secondaryLabel)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                                .autocorrectionDisabled(false)
                                .disableAutocorrection(false)
                                .font(.system(size: 18, design: .serif))
                        }
                    }
                    .frame(maxHeight: 80)

                    Spacer()
                }
            }
            .frame(maxWidth: 1280)
        }
    }

    private func TagCheckAndDescriptionView() -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    ValidationLabel(pageHashtagCheck, validation: !missingTag, validColor: .green)
                    Spacer()
                }
                .frame(height: 20)

                HStack(alignment: .center) {
                    ValidationLabel(excludedHashtagCheck, validation: !hasExcludedHashtag, validColor: .green)
                    Spacer()
                }
                .frame(height: 20)

                HStack(alignment: .center) {
                    ValidationLabel("Post description:", validation: !description.isEmpty, validColor: .green)
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                ScrollView {
                    HStack {
                        if #available(macOS 14.0, *) {
                            TextEditor(text: .constant(description))
                                .scrollIndicators(.never)
                                .focusable(false)
                                .frame(maxWidth: 960, maxHeight: .infinity, alignment: .leading)
                                .textEditorStyle(.plain)
                                .foregroundStyle(Color.label, Color.secondaryLabel)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                                .autocorrectionDisabled(false)
                                .disableAutocorrection(false)
                                .font(.system(size: 14))
                        } else {
                            TextEditor(text: .constant(description))
                                .scrollIndicators(.never)
                                .focusable(false)
                                .frame(maxWidth: 960, maxHeight: .infinity, alignment: .leading)
                                .foregroundStyle(Color.label, Color.secondaryLabel)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                                .autocorrectionDisabled(false)
                                .disableAutocorrection(false)
                                .font(.system(size: 14))
                        }

                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
            }
            .frame(maxWidth: 1280)
        }
    }

    private func PageAndHubCommentsView() -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                if !pageComments.isEmpty {
                    HStack(alignment: .center) {
                        ValidationLabel("Found comments from page (possibly already featured on page): ", validation: true, validColor: .red)
                        Spacer()
                    }
                    .frame(height: 20)

                    ScrollView {
                        ForEach(pageComments.sorted { $0.2 ?? .distantPast < $1.2 ?? .distantPast }, id: \.0) { comment in
                            HStack(alignment: .center) {
                                Text("\(comment.0) [\(comment.2.formatTimestamp())]: \(comment.1)")
                                    .foregroundStyle(.red, .black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxHeight: 40)
                }

                if !pageComments.isEmpty && !hubComments.isEmpty {
                    Divider()
                }

                if !hubComments.isEmpty {
                    HStack(alignment: .center) {
                        ValidationLabel("Found comments from hub (possibly already featured on another page): ", validation: true, validColor: .orange)
                        Spacer()
                    }
                    .frame(height: 20)

                    ScrollView {
                        ForEach(hubComments.sorted { $0.2 ?? .distantPast < $1.2 ?? .distantPast }, id: \.0) { comment in
                            HStack(alignment: .center) {
                                Text("\(comment.0) [\(comment.2.formatTimestamp())]: \(comment.1)")
                                    .foregroundStyle(.orange, .black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxHeight: 40)
                }

                if moreComments {
                    Divider()
                    HStack(alignment: .center) {
                        ValidationLabel("There were more comments than downloaded in the post, open the post IN VERO to check to previous features.", validation: true, validColor: .orange)
                        Spacer()
                    }
                    .frame(height: 20)
                }
            }
            .frame(maxWidth: 1280)
        }
    }

    private func MoreCommentsView() -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    ValidationLabel("There were more comments than downloaded in the post, open the post IN VERO to check to previous features.", validation: true, validColor: .orange)

                    Spacer()
                }
                .frame(height: 20)
            }
            .frame(maxWidth: 1280)
        }
    }

    private func ImagesView() -> some View {
        VStack(alignment: .center) {
            HStack(alignment: .center) {
                ValidationLabel("Image\(imageUrls.count == 1 ? "" : "s") found: ", validation: imageUrls.count > 0, validColor: .green)
                ValidationLabel("\(imageUrls.count)", validation: imageUrls.count > 0, validColor: .accentColor)
                
                Spacer()
            }
            .frame(height: 20)
            .frame(maxWidth: 1280)
            .padding([.leading, .trailing])
            
            CarouselView(viewModel: viewModel, images: imageUrls, userName: userName)
                .frame(minWidth: 20, maxWidth: 1280)
        }
    }

    private func LoggingView() -> some View {
        VStack {
            HStack(alignment: .top) {
                ValidationLabel("LOGGING: ", validation: true, validColor: .orange)

                Spacer()

                Button(action: {
                    logger.verbose("Tapped copy for log", context: "User")
                    copyToClipboard(logging.map { $0.1 }.joined(separator: "\n"))
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the logging data to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                        Text("Copy log")
                    }
                }
                .focusable()
                .onKeyPress(.space) {
                    logger.verbose("Pressed space on copy for log", context: "User")
                    copyToClipboard(logging.map { $0.1 }.joined(separator: "\n"))
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the logging data to the clipboard")
                    return .handled
                }
            }
            .frame(maxWidth: 1280)

            ScrollView(.horizontal) {
                ForEach(Array(logging.enumerated()), id: \.offset) { _, log in
                    Text(log.1)
                        .foregroundStyle(log.0, .black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: 1280, maxHeight: .infinity)
        }
    }

    // MARK: - user level navigation

    /// Navigates to a user level using the given direction.
    /// - Parameters:
    ///   - direction: The `Direction` for the navigation.
    private func navigateToUserLevel(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(MembershipCase.casesFor(hub: viewModel.currentPage?.hub ?? ""), viewModel.membership, direction)
        if change {
            if direction != .same {
                viewModel.membership = newValue
            }
            viewModel.membershipValidation = viewModel.validateMembership(value: viewModel.membership)
            updateScripts()
        }
    }

    /// Navigates to a user level using the key press arrows.
    /// - Parameters:
    ///   - keyPress: The key press for the arrows.
    /// - Returns: The key press result.
    private func navigateToUserLevelWithArrows(_ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToUserLevel(direction)
            return .handled
        }
        return .ignored
    }

    /// Navigates to a user level using the key press characters as a prefix.
    /// - Parameters:
    ///   - keyPress: The key press for the characters.
    /// - Returns: The key press result.
    private func navigateToUserLevelWithPrefix(_ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(MembershipCase.casesFor(hub: viewModel.currentPage?.hub ?? ""), viewModel.membership, keyPress.characters.lowercased())
        if change {
            viewModel.membership = newValue
            viewModel.membershipValidation = viewModel.validateMembership(value: viewModel.membership)
            updateScripts()
            return .handled
        }
        return .ignored
    }
}

extension PostDownloaderView {
    // MARK: - parsing helpers

    /// Parses the contents of the loaded post.
    /// - Parameter contents: The contents of the loaded post from the server.
    @MainActor
    func parsePost(_ contents: String) {
        do {
            logger.verbose("Loaded the post from the server", context: "System")
            logging.append((.blue, "Loaded the post from the server"))
            let document = try SwiftSoup.parse(contents)
            for item in try document.select("script") {
                do {
                    let scriptText = try item.html().trimmingCharacters(in: .whitespaces)
                    if !scriptText.isEmpty {
                        let scriptLines = scriptText.split(whereSeparator: \.isNewline)
                        if scriptLines.first!.hasPrefix("window.__staticRouterHydrationData = JSON.parse(") {
                            let prefixLength = "window.__staticRouterHydrationData = JSON.parse(".count
                            let start = scriptText.index(scriptText.startIndex, offsetBy: prefixLength + 1)
                            let end = scriptText.index(scriptText.endIndex, offsetBy: -3)
                            let jsonString = String(scriptText[start ..< end])
                            // The JSON string is a JSON-encoded string, so use a wrapped JSON fragment and the JSON serialization
                            // utility to get the unencoded string which is then decoded using the JSON decoder utility.
                            let wrappedJsonString = "{\"value\": \"\(jsonString)\"}"
                            if let jsonEncodedData = wrappedJsonString.data(using: .utf8) {
                                if let jsonStringDecoded = try JSONSerialization.jsonObject(with: jsonEncodedData, options: []) as? [String: Any] {
                                    if let stringValue = (jsonStringDecoded["value"] as? String) {
                                        if let jsonData = stringValue.data(using: .utf8) {
                                            let postData = try JSONDecoder().decode(PostData.self, from: jsonData)
                                            if let profile = postData.loaderData?.entry?.profile?.profile {
                                                userAlias = profile.username ?? ""
                                                if userAlias.isEmpty && profile.name != nil {
                                                    userAlias = profile.name!.replacingOccurrences(of: " ", with: "")
                                                }
                                                logger.verbose("Loaded the profile", context: "System")
                                                logging.append((.blue, "User's alias: \(userAlias)"))
                                                userName = profile.name ?? ""
                                                logging.append((.blue, "User's name: \(userName)"))
                                                userProfileLink = profile.url ?? ""
                                                logging.append((.blue, "User's profile link: \(userProfileLink)"))
                                                userBio = (profile.bio ?? "").removeExtraSpaces()
                                                logging.append((.blue, "User's bio: \(userBio)"))

                                                profileLoaded = true
                                            } else {
                                                logger.error("Failed to find the profile information", context: "System")
                                                logging.append((.red, "Failed to find the profile information, the account is likely private"))
                                                logging.append((.red, "Post must be handled manually in VERO app"))
                                                // debugPrint(jsonString)
                                            }
                                            if let post = postData.loaderData?.entry?.post {
                                                postHashtags = []
                                                description = joinSegments(post.post?.caption, &postHashtags).removeExtraSpaces(includeNewlines: false)

                                                logger.verbose("Loaded the post information", context: "System")

                                                checkPageHashtags()
                                                checkExcludedHashtags()

                                                if let postImages = post.post?.images {
                                                    logger.verbose("Found images in the post information", context: "System")
                                                    let postImageUrls = postImages.filter({ $0.url != nil && $0.url!.hasPrefix("https://") }).map { $0.url! }
                                                    for imageUrl in postImageUrls {
                                                        logging.append((.blue, "Image source: \(imageUrl)"))
                                                        imageUrls.append(URL(string: imageUrl)!)
                                                    }
                                                }

                                                if let currentPage = viewModel.currentPage {
                                                    if currentPage.hub == "click" || currentPage.hub == "snap" {
                                                        commentCount = post.post?.comments ?? 0
                                                        likeCount = post.post?.likes ?? 0
                                                        if let comments = post.comments {
                                                            moreComments = comments.count < commentCount
                                                            for comment in comments {
                                                                if let userName = comment.author?.username {
                                                                    if userName.lowercased().hasPrefix("\(currentPage.hub.lowercased())_") {
                                                                        if userName.lowercased() == currentPage.displayName.lowercased() {
                                                                            pageComments.append((
                                                                                comment.author?.name ?? userName,
                                                                                joinSegments(comment.content).removeExtraSpaces(),
                                                                                (comment.timestamp ?? "").timestamp(),
                                                                                String(userName[userName.index(userName.startIndex, offsetBy: currentPage.hub.count + 1) ..< userName.endIndex].lowercased())
                                                                            ))
                                                                            logger.verbose("Found comment from page", context: "System")
                                                                            logging.append((.red, "Found comment from page - possibly already featured on page"))
                                                                        } else {
                                                                            hubComments.append((
                                                                                comment.author?.name ?? userName,
                                                                                joinSegments(comment.content).removeExtraSpaces(),
                                                                                (comment.timestamp ?? "").timestamp(),
                                                                                String(userName[userName.index(userName.startIndex, offsetBy: currentPage.hub.count + 1) ..< userName.endIndex].lowercased())
                                                                            ))
                                                                            logger.verbose("Found comment from another hub page", context: "System")
                                                                            logging.append((.orange, "Found comment from another hub page - possibly already feature on another page"))
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        } else {
                                                            moreComments = commentCount != 0
                                                            if moreComments {
                                                                logger.verbose("Not all comments loaded", context: "System")
                                                                logging.append((.orange, "Not all comments found in post, check VERO app to see all comments"))
                                                            }
                                                        }
                                                    }
                                                }
                                            } else {
                                                logger.error("Failed to find the post information", context: "System")
                                                logging.append((.red, "Failed to find the post information, the account is likely private"))
                                                logging.append((.red, "Post must be handled manually in VERO app"))
                                                // debugPrint(jsonString)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    logger.error("Failed to parse the post information: \(error.localizedDescription)", context: "System")
                    debugPrint(error.localizedDescription)
                    viewModel.dismissAllNonBlockingToasts(includeProgress: true)
                    viewModel.showToast(
                        .alert,
                        "Failed to parse the post data on the post",
                        "Failed to parse the post information from the downloaded post - \(error.localizedDescription)"
                    )
                }
            }

            if imageUrls.isEmpty {
                throw AccountError.PrivateAccount
            }

            postLoaded = true
        } catch let error as AccountError {
            logger.error("Failed to download and parse the post information - \(error.errorDescription ?? "unknown")", context: "System")
            logging.append((.red, "Failed to download and parse the post information - \(error.errorDescription ?? "unknown")"))
            logging.append((.red, "Post must be handled manually in VERO app"))
            viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            viewModel.showToast(
                .error,
                "Failed to load and parse post",
                "Failed to download and parse the post information - \(error.errorDescription ?? "unknown")")
        } catch {
            logger.error("Failed to download and parse the post information - \(error.localizedDescription)", context: "System")
            logging.append((.red, "Failed to download and parse the post information - \(error.localizedDescription)"))
            logging.append((.red, "Post must be handled manually in VERO app"))
            viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            viewModel.showToast(
                .error,
                "Failed to load and parse post",
                "Failed to download and parse the post information - \(error.localizedDescription)")
        }
    }

    /// Account error enumeration for throwing account-specifc error codes.
    enum AccountError: String, LocalizedError {
        case PrivateAccount = "Could not find any images, this account might be private"
        public var errorDescription: String? { rawValue }
    }

    /// Loads the feature using the postUrl.
    private func loadFeature() async {
        logger.verbose("Loading feature post", context: "System")
        if let postLink = viewModel.postLink, let url = URL(string: postLink) {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let session = URLSession(configuration: URLSessionConfiguration.default)
            session.dataTask(with: request) { data, _, error in
                if let data = data {
                    let contents = String(data: data, encoding: .utf8)!
                    Task { @MainActor in
                        parsePost(contents)
                        viewModel.dismissAllNonBlockingToasts(includeProgress: true)
                    }
                } else if let error = error {
                    Task { @MainActor in
                        logger.error("Failed to download and parse the post information - \(error.localizedDescription)", context: "System")
                        logging.append((.red, "Failed to download and parse the post information - \(error.localizedDescription)"))
                        logging.append((.red, "Post must be handled manually in VERO app"))
                        viewModel.dismissAllNonBlockingToasts(includeProgress: true)
                        viewModel.showToast(
                            .error,
                            "Failed to load and parse post",
                            "Failed to download and parse the post information - \(error.localizedDescription)")
                    }
                }
            }.resume()
        } else {
            Task { @MainActor in
                viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            }
        }
    }

    // MARK: - excluded hash tags

    /// Loads the excluded hashtags for the current page.
    private func loadExcludedTagsForPage() {
        if let currentPage = viewModel.currentPage {
            excludedHashtags = UserDefaults.standard.string(forKey: "ExcludedHashtags_" + currentPage.id) ?? ""
        }
    }

    /// Stores the excluded hashtags for the current page.
    private func storeExcludedTagsForPage() {
        if let currentPage = viewModel.currentPage {
            UserDefaults.standard.set(excludedHashtags, forKey: "ExcludedHashtags_" + currentPage.id)
        }
        checkExcludedHashtags()
    }

    /// Checks for the page hashtag.
    private func checkPageHashtags() {
        var pageHashTagFound = ""
        if let currentPage = viewModel.currentPage {
            let pageHashTags = currentPage.hashTags
            if postHashtags.firstIndex(where: { postHashTag in
                pageHashTags.firstIndex(where: { pageHashTag in
                    if postHashTag.lowercased() == pageHashTag.lowercased() {
                        pageHashTagFound = pageHashTag.lowercased()
                        return true
                    }
                    return false
                }) != nil
            }) != nil {
                pageHashtagCheck = "Contains page hashtag \(pageHashTagFound)"
                logging.append((.blue, pageHashtagCheck))
            } else {
                pageHashtagCheck = "MISSING page hashtag!!"
                logging.append((.orange, "\(pageHashtagCheck)"))
                missingTag = true
            }
        } else {
            pageHashtagCheck = "MISSING page!!"
            logging.append((.orange, "\(pageHashtagCheck)"))
            missingTag = true
        }
    }

    /// Checks for any excluded hashtags.
    private func checkExcludedHashtags() {
        hasExcludedHashtag = false
        excludedHashtagCheck = ""
        if !excludedHashtags.isEmpty {
            let excludedTags = excludedHashtags.split(separator: ",", omittingEmptySubsequences: true)
            for excludedTag in excludedTags {
                if postHashtags.includes("#\(String(excludedTag))") {
                    hasExcludedHashtag = true
                    excludedHashtagCheck = "Post has excluded hashtag \(excludedTag)!"
                    logging.append((.red, excludedHashtagCheck))
                    break
                }
            }
        }
        if excludedHashtagCheck.isEmpty {
            if excludedHashtags.isEmpty {
                excludedHashtagCheck = "Post does not contain any excluded hashtags"
                logging.append((.blue, excludedHashtagCheck))
            } else {
                excludedHashtagCheck = "No excluded hashtags to check"
                logging.append((.blue, excludedHashtagCheck))
            }
        }
    }
}
