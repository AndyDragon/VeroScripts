//
//  ReportDocument.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2025-02-07.
//

import SwiftUI
import UniformTypeIdentifiers

struct ReportDocument: FileDocument {
    static var readableContentTypes = [UTType.plainText]
    var text = ""

    init(initialText: String = "") {
        text = initialText
    }

    init(report: String) {
        text = report
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
