//
//  Language.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/31.
//  Edited by Lane Shukhov on 2024/10/21.
//

import Cocoa

enum Language: String, CaseIterable, Identifiable, Codable {
    case system = "Follow System"
    case english = "English"
    case russian = "Russian"

    var id: String { rawValue }

    var localized: String {
        NSLocalizedString(rawValue, comment: "")
    }

    func apply() {
        let languageCode: String?
        let local = Calendar.autoupdatingCurrent.locale?.identifier
        let region = local?.split(separator: "@").last?.split(separator: "_").last

        switch self {
        case .system:
            if region == "RU" {
                languageCode = "ru"
            } else {
                languageCode = "en"
            }
        case .english:
            languageCode = "en"
        case .russian:
            languageCode = "ru"
        }

        Bundle.setLanguage(languageCode)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSAlert.popRestart(
                NSLocalizedString("The language has been changed. The app will restart for the changes to take effect.", comment: ""),
                completion: relaunchApp
            )
        }
    }
}

private func relaunchApp() {
    let path = Bundle.main.bundlePath
    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = ["-n", path]
    task.launch()
    exit(0)
}

private extension Bundle {
    private static var onLanguageDispatchOnce: () -> Void = {
        object_setClass(Bundle.main, PrivateBundle.self)
    }

    static func setLanguage(_ language: String?) {
        onLanguageDispatchOnce()

        if let language {
            UserDefaults.standard.set([language], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }
}

private class PrivateBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
              let languageCode = languages.first,
              let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath)
        else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}
