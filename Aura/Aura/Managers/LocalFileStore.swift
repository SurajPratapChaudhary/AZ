//
//  LocalFileStore.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import Foundation

final class LocalFileStore {
    private let baseURL: URL

    init() {
        baseURL = FileManager.default.temporaryDirectory.appendingPathComponent("aura", isDirectory: true)
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    func write(data: Data, ext: String, name: String = UUID().uuidString) throws -> URL {
        let url = baseURL.appendingPathComponent("\(name).\(ext)")
        try data.write(to: url, options: [.atomic])
        return url
    }
}
