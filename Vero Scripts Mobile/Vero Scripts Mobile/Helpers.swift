//
//  Helpers.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-02-10.
//

import Combine
import SwiftUI

extension Binding where Value: Equatable {
    @discardableResult func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                if self.wrappedValue != newValue {
                    self.wrappedValue = newValue
                    handler(newValue)
                }
            }
        )
    }
}

extension View {
    @ViewBuilder func onValueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
        if #available(macOS 14.0, *) {
            self.onChange(of: value) { _, newValue in
                onChange(newValue)
            }
        } else {
            onReceive(Just(value)) { value in
                onChange(value)
            }
        }
    }
}

func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

func matches(of regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(
            in: text,
            range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        debugPrint("invalid regex: \(error.localizedDescription)")
        return []
    }
}

extension Locale {
    static var preferredLanguageCode: String {
        guard let preferredLanguage = preferredLanguages.first,
              let code = Locale(identifier: preferredLanguage).language.languageCode?.identifier
        else {
            return "en"
        }
        return code
    }

    static var preferredLanguageCodes: [String] {
        return Locale.preferredLanguages.compactMap({ Locale(identifier: $0).language.languageCode?.identifier })
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
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 40.0)
        let (data, _) = try await data(for: request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dataDecodingStrategy = dataDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy

        let decoded = try decoder.decode(T.self, from: data)
        return decoded
    }
}


func copyToClipboard(_ text: String) {
    let pasteBoard = UIPasteboard.general
    pasteBoard.string = text
}

func stringFromClipboard() -> String {
    let pasteBoard = UIPasteboard.general
    return pasteBoard.string ?? ""
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

    var displayName: String? {
        return infoDictionary?["CFBundleDisplayName"] as? String ?? infoDictionary?["CFBundleName"] as? String
    }
}

@resultBuilder
public struct StringBuilder {
    public static func buildBlock(_ components: String...) -> String {
        return components.reduce("", +)
    }
}

let pattern = "(^|\\s|\\()@([\\w]+)(\\s|$|,|\\.|\\:|\\))"
let regex = try! NSRegularExpression(pattern: pattern, options: [])

extension String {
    public init(@StringBuilder _ builder: () -> String) {
        self.init(builder())
    }

    public func timestamp() -> Date? {
        let dateParserFormatter = DateFormatter()
        dateParserFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        dateParserFormatter.timeZone = .gmt
        return dateParserFormatter.date(from: self)
    }

    public func removeExtraSpaces(includeNewlines: Bool = true) -> String {
        if includeNewlines {
            return replacingOccurrences(of: "[\\s]+", with: " ", options: .regularExpression)
        }
        return split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "[\\s]+", with: " ", options: .regularExpression) }
            .joined(separator: "\n")
    }

    static func * (str: String, repeatTimes: Int) -> String {
        return String(repeating: str, count: repeatTimes)
    }

    func insertSpacesInUserTags(_ doReplacements: Bool = false) -> String {
        if !doReplacements {
            return self
        }
        let range = NSRange(self.startIndex..<self.endIndex, in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1@ $2$3")
    }
}

extension Double {
    public func formatUsingPrecision(_ precision: Int) -> String {
        return String(format: "%.\(precision)f", self)
    }
}

extension Date? {
    public func formatTimestamp() -> String {
        if let date = self {
            let distance = -date.timeIntervalSinceNow
            let days = floor(distance / (24 * 60 * 60))
            if days <= 1 {
                let hours = floor(distance / (60 * 60))
                return "\(hours.formatUsingPrecision(0))h"
            } else if days <= 7 {
                return "\(days.formatUsingPrecision(0))d"
            }
            let components = Calendar.current.dateComponents([.year], from: date)
            let componentsNow = Calendar.current.dateComponents([.year], from: Date.now)
            let dateFormatter = DateFormatter()
            if components.year == componentsNow.year {
                dateFormatter.dateFormat = "MMM d"
            } else {
                dateFormatter.dateFormat = "MMM d, yyyy"
            }
            return dateFormatter.string(from: date)
        }
        return "-"
    }
}

extension [String] {
    func includes(_ element: String) -> Bool {
        return contains(where: { item in item == element })
    }

    func includesWithoutCase(_ element: String) -> Bool {
        return contains(where: { item in item.lowercased() == element.lowercased() })
    }
}

extension URL {
    var lastPathComponentWithoutExtension: String {
        return String(NSString(string: lastPathComponent).deletingPathExtension)
    }
}

struct RuntimeError: LocalizedError {
    let description: String

    init(_ description: String) {
        self.description = description
    }

    var errorDescription: String? {
        description
    }
}

extension View {
    public nonisolated func safeToolbarVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View {
        if #available(iOS 18.0, *) {
            for bar in bars {
                _ = self.toolbarVisibility(visibility, for: bar)
            }
            return self
        }
        return self
    }

    @inlinable public nonisolated func safeMinWidthFrame(minWidth: CGFloat, maxWidth: CGFloat) -> some View {
        if #available(iOS 18.0, *) {
            return self.frame(minWidth: minWidth, maxWidth: maxWidth)
        }
        return frame(maxWidth: maxWidth)
    }
}
