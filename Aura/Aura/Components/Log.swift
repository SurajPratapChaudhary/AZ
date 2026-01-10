//
//  Log.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import Foundation

enum Log {
    static func d(_ message: String,
                  file: String = #fileID,
                  function: String = #function,
                  line: Int = #line) {
#if DEBUG
        print("🟩 \(file):\(line) \(function) | \(message)")
#endif
    }

    static func e(_ message: String,
                  file: String = #fileID,
                  function: String = #function,
                  line: Int = #line) {
#if DEBUG
        print("🟥 \(file):\(line) \(function) | \(message)")
#endif
    }
}
