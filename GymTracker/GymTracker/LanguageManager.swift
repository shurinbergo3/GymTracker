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
            refreshID = UUID()
        }
    }
    
    @Published var refreshID = UUID()
    private(set) var bundle: Bundle = .main
    private var stringsDict: [String: String] = [:]
    
    init() {
        updateBundle()
    }
    
    var currentLanguageCode: String {
        switch appLanguage {
        case "ru": return "ru"
        case "en": return "en"
        case "pl": return "pl"
        case "de": return "de"
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
        loadStrings()
    }
    
    private func loadStrings() {
        stringsDict = [:]
        let lang = currentLanguageCode
        guard let lprojPath = Bundle.main.path(forResource: lang, ofType: "lproj") else { return }
        let stringsPath = (lprojPath as NSString).appendingPathComponent("Localizable.strings")
        if let dict = NSDictionary(contentsOfFile: stringsPath) as? [String: String] {
            stringsDict = dict
        }
    }
    
    func localizedString(_ key: String) -> String {
        return stringsDict[key] ?? key
    }

    /// Builds a YouTube search query for an exercise in the user's current app language.
    /// The exercise name is localized and a language-specific "technique" suffix is appended,
    /// so a user gets results in the same language the app is set to.
    func youtubeSearchQuery(forExerciseNamed exerciseName: String) -> String {
        let localizedName = exerciseName.localized()
        let suffix: String
        switch currentLanguageCode {
        case "en": suffix = "technique"
        case "pl": suffix = "technika"
        case "de": suffix = "Technik"
        default:   suffix = "техника выполнения"
        }
        return "\(localizedName) \(suffix)"
    }
}

extension String {
    func localized() -> String {
        LanguageManager.shared.localizedString(self)
    }
}
