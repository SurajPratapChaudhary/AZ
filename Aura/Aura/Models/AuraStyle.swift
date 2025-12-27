//
//  AuraStyle.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import Foundation

enum AuraStyle: String, CaseIterable, Identifiable, Codable {
    case luxury = "Luxury"
    case cinematic = "Cinematic"
    case clean = "Clean"
    case editorial = "Editorial"
    case night = "Night"

    var id: String { rawValue }
}
