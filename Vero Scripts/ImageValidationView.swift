//
//  ImageValidationView.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-03-11.
//

import SwiftUI
import SwiftyBeaver
import UniformTypeIdentifiers

enum AiVerdict {
    case notAi
    case ai
    case indeterminate
}

struct ImageValidationView: View {
    @Environment(\.openURL) private var openURL

    private var viewModel: ContentView.ViewModel
    @State private var focusedField: FocusState<FocusedField?>.Binding

    @State private var aiVerdictString = ""
    @State private var aiVerdict = AiVerdict.indeterminate
    @State private var returnedJson = ""
    @State private var errorFromServer = ""
    @State private var uploadToServer: String? = nil
    @State private var loadedImageUrl: URL?
    @State private var isLoading = false
    @State private var error: Error?

    private let languagePrefix = Locale.preferredLanguageCode
    private let logger = SwiftyBeaver.self

    init(
        _ viewModel: ContentView.ViewModel,
        _ focusedField: FocusState<FocusedField?>.Binding
    ) {
        self.viewModel = viewModel
        self.focusedField = focusedField
    }

    var body: some View {
        ZStack {
            Color.backgroundColor.edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    ValidationSummaryView()

                    CustomTabView(tabBarPosition: .top, content: [
                        (
                            tabText: "TinEye Results",
                            tabIconName: "globe",
                            tabIconColors: (.accentColor, .secondary),
                            view: AnyView(TinEyeResultsView())
                        ),
                        (
                            tabText: "HIVE Results",
                            tabIconName: "photo.badge.checkmark.fill",
                            tabIconColors: (.secondary, .accentColor),
                            view: AnyView(HiveAiResultsView())
                        ),
                    ])
                }

                Spacer()
                    .frame(height: 8)

                HStack {
                    Image(systemName: uploadToServer != nil ? "arrow.triangle.2.circlepath.icloud" : "icloud")
                        .foregroundColor(uploadToServer != nil ? .yellow : .green)
                        .symbolEffect(.pulse, options: uploadToServer != nil ? .repeating.speed(3) : .default, value: uploadToServer)
                        .symbolRenderingMode(uploadToServer != nil ? .hierarchical : .monochrome)
                    if let uploadToServer {
                        Text("Sending image to \(uploadToServer)...")
                    }
                    Spacer()
                }
                .font(.system(size: 16))
                .padding(.bottom, 10)
            }
            .padding([.leading, .top, .trailing])
            .foregroundStyle(Color.label, Color.secondaryLabel)
            .toolbar {
                Button(action: {
                    viewModel.visibleView = .PostDownloadView
                }) {
                    HStack {
                        Image(systemName: "xmark")
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
                .disabled(viewModel.hasModalToasts || uploadToServer != nil)
                .keyboardShortcut(languagePrefix == "en" ? "`" : "x", modifiers: languagePrefix == "en" ? .command : [.command, .option])
            }
        }
        .frame(minWidth: 1280, minHeight: 800)
        .background(Color.backgroundColor)
        .onAppear {
            openTinEyeResults()
            prepareHiveResults()
        }
    }

    // MARK: - sub views

    private func ValidationSummaryView() -> some View {
        HStack(alignment: .center) {
            Spacer()
                .frame(width: 0, height: 26)
            if !aiVerdictString.isEmpty {
                HStack {
                    Text("HIVE verdict: ")
                    Text(aiVerdictString)
                    Image(systemName: aiVerdict == .notAi ? "checkmark.shield" : aiVerdict == .ai ? "exclamationmark.warninglight" : "questionmark.diamond")
                }
                .font(.system(size: 24))
                .foregroundStyle(aiVerdict == .notAi ? .green : aiVerdict == .ai ? .red : .yellow, .secondary)
            }

            Spacer()
        }
    }

    private func TinEyeResultsView() -> some View {
        VStack {
            if let realizedImageUrl = loadedImageUrl {
                ZStack {
                    VStack(alignment: .leading) {
                        Button(action: {
                            openURL(realizedImageUrl)
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "arrow.up.right.bottomleft.rectangle")
                                    .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                                    .font(.system(size: 28, weight: .semibold))
                                Text("Open in browser")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .padding(4)
                        }
                        .padding(.vertical, 4)
                        PlatformIndependentWebView(url: realizedImageUrl, isLoading: $isLoading, error: $error)
                            .cornerRadius(4)
                    }
                    if isLoading {
                        ProgressView()
                            .scaleEffect(2)
                    }
                }
            } else {
                Spacer()
                Text("Enter an image URL to search")
                Spacer()
            }
        }
    }

    private func HiveAiResultsView() -> some View {
        VStack {
            if !returnedJson.isEmpty {
                HStack {
                    Spacer()
                    Button(action: {
                        copyToClipboard(returnedJson)
                        viewModel.showSuccessToast("Copied to clipboard", "Copied the logging data to the clipboard")
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "pencil.and.list.clipboard")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                            Text("Copy result")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        copyToClipboard(returnedJson)
                        viewModel.showSuccessToast("Copied to clipboard", "Copied the logging data to the clipboard")
                        return .handled
                    }
                }
                ScrollView(.vertical) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Result from server: ")
                                .font(.system(size: 16))
                                .bold()
                                .padding([.top, .leading], 8)
                            Spacer().frame(height: 0) // fix bug with text being truncated
                            Text(returnedJson)
                                .lineLimit(...2048)
                                .padding(8)
                            Spacer().frame(height: 0) // fix bug with text being truncated
                        }
                        Spacer()
                    }
                }
                .background(Color.controlBackground)
                .cornerRadius(10)
            }

            if !errorFromServer.isEmpty {
                HStack {
                    Text("Error: ")
                    Text(errorFromServer)
                }
                .font(.system(size: 32))
                .foregroundStyle(.red, .secondary)
            }

            Spacer()
        }
    }
}

extension ImageValidationView {
    // MARK: - utilities

    private func openTinEyeResults() {
        logger.verbose("Opening the TinEye browser URL", context: "System")
        if let imageUrlToEncode = viewModel.imageValidationImageUrl {
            let finalUrl = imageUrlToEncode.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            loadedImageUrl = URL(string: "https://www.tineye.com/search/?pluginver=chrome-2.0.4&sort=score&order=desc&url=\(finalUrl!)")
        }
    }

    private func prepareHiveResults() {
        logger.verbose("Loading results from HIVE", context: "System")
        viewModel.showToast(.progress, "Loading", "Loading image AI data from HIVE...")
        Task {
            aiVerdict = .indeterminate
            aiVerdictString = ""
            errorFromServer = ""
            returnedJson = ""
            sendToHiveServer()
        }
    }

    private func sendToHiveServer() {
        uploadToServer = "Hive"
        returnedJson = ""
        aiVerdict = .indeterminate
        aiVerdictString = ""
        errorFromServer = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-d-HH-mm-ss"
        sendRequestToHive { data, _, error in
            uploadToServer = nil
            if let errorResult = error {
                errorFromServer = "Error result: " + errorResult.localizedDescription
                logger.error("Error result from HIVE: \(errorResult.localizedDescription)", context: "System")
                debugPrint("Error result: " + errorResult.localizedDescription)
                viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            } else if let dataResult = data {
                logger.verbose("Received result from HIVE", context: "System")
                do {
                    returnedJson = String(data: dataResult, encoding: .utf8) ?? ""
                    let decoder = JSONDecoder()
                    let results = try decoder.decode(HiveResponse.self, from: dataResult)
                    if results.status_code >= 200 && results.status_code <= 299 {
                        if let verdictClass = results.data.classes.first(where: { $0.class == "not_ai_generated" }) {
                            aiVerdictString = "\(verdictClass.score > 0.8 ? "Not AI" : verdictClass.score < 0.5 ? "AI" : "Indeterminate") (\(String(format: "%.1f", verdictClass.score * 100)) % not AI)"
                            aiVerdict = verdictClass.score > 0.8 ? .notAi : verdictClass.score < 0.5 ? .ai : .indeterminate
                        }
                    } else {
                        aiVerdictString = "unknown (non-success result)"
                        aiVerdict = .indeterminate
                    }
                    if let json = try? JSONSerialization.jsonObject(with: dataResult, options: .mutableContainers),
                       let jsonData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) {
                        returnedJson = String(decoding: jsonData, as: UTF8.self)
                    }
                    logger.verbose("Parsed result from HIVE", context: "System")
                } catch {
                    logger.error("Error parsing results from HIVE: \(error.localizedDescription)", context: "System")
                    do {
                        let decoder = JSONDecoder()
                        let results = try decoder.decode(ServerMessage.self, from: dataResult)
                        errorFromServer = results.message
                        logger.error("Error from HIVE: \(errorFromServer)", context: "System")
                    } catch {
                        logger.error("JSON decode error decoding HIVE response: \(error.localizedDescription)", context: "System")
                        errorFromServer = "JSON decode error: " + error.localizedDescription
                        debugPrint("JSON decode error: " + error.localizedDescription)
                        debugPrint(String(decoding: dataResult, as: UTF8.self))
                    }
                }
                viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            }
        }
    }

    private func sendRequestToHive(
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        aiVerdict = .indeterminate
        aiVerdictString = ""
        errorFromServer = ""
        let url = "https://plugin.hivemoderation.com/api/v1/image/ai_detection"
        var request = MultipartFormDataRequest(url: URL(string: url)!)
        request.addHeader(header: "Accept", value: "application/json")
        request.addDataField(fieldName: "url", fieldValue: viewModel.imageValidationImageUrl!.absoluteString)
        request.addDataField(fieldName: "request_id", fieldValue: UUID().uuidString)
        URLSession.shared.dataTask(with: request, completionHandler: completionHandler).resume()
    }
}

struct ServerResponse: Decodable {
    var id: String
    var created_at: String
    var report: ServerReport
    var facets: ResultFacets
}

struct ServerMessage: Decodable {
    var request_id: String
    var message: String
    var current_limit: String?
    var current_usage: String?
}

struct ServerReport: Decodable {
    var verdict: String
    var ai: DetectionResult
    var human: DetectionResult
}

struct DetectionResult: Decodable {
    var is_detected: Bool
}

struct ResultFacets: Decodable {
    var quality: Facet?
    var nsfw: Facet
}

struct Facet: Decodable {
    var version: String
    var is_detected: Bool
}

struct HiveResponse: Decodable {
    var data: HiveData
    var message: String
    var status_code: Int
}

struct HiveData: Decodable {
    var classes: [HiveClass]
}

struct HiveClass: Decodable {
    var `class`: String
    var score: Double
}
