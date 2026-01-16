//
//  CGFloat+.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 16/01/26.
//


import SwiftUI

extension CGFloat {
    
    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    static func screenHeightPercentage(_ percent: Int) -> CGFloat {
        return (.screenHeight * CGFloat(percent / 100))
    }
    
    static func screenWidthPercentage(_ percent: Int) -> CGFloat {
        return (.screenWidth * CGFloat(Double(percent) / Double(100)))
    }
    
    static var safeAreaTop: CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        return keyWindow?.safeAreaInsets.top ?? 0
    }
    
    static var safeAreaBottom: CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        return keyWindow?.safeAreaInsets.bottom ?? 0
    }
}
