//
//  Helpers.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI

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

extension URLSession {
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from url: URL,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .deferredToData,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
    ) async throws -> T {
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

func copyToClipboard(_ text: String) -> Void {
#if os(iOS)
        UIPasteboard.general.string = text
#else
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.writeObjects([text as NSString])
#endif
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    var releaseVersionNumberPretty: String {
        return "\(releaseVersionNumber ?? "1.0").\(buildVersionNumber ?? "0")"
    }
    func releaseVersionOlder(than: String) -> Bool {
        return releaseVersionNumberPretty.compare(than, options: .numeric) == .orderedAscending
    }
}

@resultBuilder
public struct StringBuilder {
    public static func buildBlock(_ components: String...) -> String {
        return components.reduce("", +)
    }
}

public extension String {
    init(@StringBuilder _ builder: () -> String) {
        self.init(builder())
    }
}

import SystemColors

extension Color {
    static var currentTheme = ""
    
    static var theme: Color  {
        return Color("theme")
    }
    static var BackgroundColor: Color  {
        if currentTheme.isEmpty {
            //return Color(nsColor: .windowBackgroundColor)
            return .windowBackground
        }
        return Color("\(currentTheme)/BackgroundColor")
    }
    static var BackgroundColorEditor: Color  {
        if currentTheme.isEmpty {
            //return Color(nsColor: .windowBackgroundColor)
            return .controlBackground.opacity(0.5)
        }
        return Color("\(currentTheme)/BackgroundColorEditor")
    }
    static var BackgroundColorList: Color  {
        if currentTheme.isEmpty {
            //return Color(nsColor: .controlBackgroundColor)
            return .controlBackground
        }
        return Color("\(currentTheme)/BackgroundColorList")
    }
    static var BackgroundColorNavigationBar: Color  {
        if currentTheme.isEmpty {
            //return Color(nsColor: .windowBackgroundColor)
            return .windowBackground
        }
        return Color("\(currentTheme)/BackgroundColorNavigationBar")
    }
    static var ColorPrimary: Color  {
        if currentTheme.isEmpty {
            //return Color(nsColor: .highlightColor)
            return .highlight
        }
        return Color("\(currentTheme)/ColorPrimary")
    }
    static var AccentColor: Color  {
        if currentTheme.isEmpty {
            //return Color(nsColor: .systemGray)
            return .accentColor
        }
        return Color("\(currentTheme)/AccentColor")
    }
    static var TextColorPrimary: Color  {
        if currentTheme.isEmpty {
            //return Color(nsColor: .labelColor)
            return .label
        }
        return Color("\(currentTheme)/TextColorPrimary")
    }
    static var TextColorRequired: Color  {
        if currentTheme.isEmpty {
            return .red
        }
        return Color("\(currentTheme)/TextColorRequired")
    }
    static var TextColorSecondary: Color  {
        if currentTheme.isEmpty {
            //return Color(nsColor: .secondaryLabelColor)
            return .secondaryLabel
        }
        return Color("\(currentTheme)/TextColorSecondary")
    }
}

class Constants {
    public static let THEME = "THEME"
}

class UserDefaultsUtils {
    static var shared = UserDefaultsUtils()
    
    func setTheme(theme: Theme) {
        UserDefaults.standard.set(theme.rawValue, forKey: Constants.THEME)
    }
    
    func getTheme() -> Theme {
        return Theme(rawValue: UserDefaults.standard.string(forKey: Constants.THEME) ?? Theme.darkSubtleGray.rawValue) ?? Theme.darkSubtleGray
    }
}
