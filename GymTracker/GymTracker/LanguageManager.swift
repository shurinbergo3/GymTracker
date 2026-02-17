//
//  LanguageManager.swift
//  GymTracker
//
//  Created for app localization
//

import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("appLanguage") var appLanguage: String = "system" {
        didSet {
            updateBundle()
            objectWillChange.send()
        }
    }
    
    /// The bundle for the currently selected language
    private(set) var bundle: Bundle = .main
    
    init() {
        updateBundle()
    }
    
    var currentLanguageCode: String {
        switch appLanguage {
        case "ru": return "ru"
        case "en": return "en"
        default: return Locale.current.language.languageCode?.identifier ?? "ru"
        }
    }
    
    var currentLocale: Locale {
        Locale(identifier: currentLanguageCode)
    }
    
    private func updateBundle() {
        let lang = currentLanguageCode
        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            self.bundle = langBundle
        } else {
            self.bundle = .main
        }
    }
    
    func localizedString(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}

extension String {
    func localized() -> String {
        LanguageManager.shared.localizedString(self)
    }
}
