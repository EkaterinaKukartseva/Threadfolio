//
//  PrivacyPolicy.swift
//  Threadfolio
//
//  Created by Ekaterina on 02.11.2026.
//

import Foundation

/// Политика конфиденциальности на сайте приложения, на языке интерфейса.
nonisolated enum PrivacyPolicy {

    static var url: URL? {
        url(language: Bundle.main.preferredLocalizations.first ?? "en")
    }

    static func url(language: String) -> URL? {
        let page = language == "ru" ? "privacy-ru.html" : "privacy.html"
        return URL(string: "https://ekaterinakukartseva.github.io/threadfolio-site/\(page)")
    }
}
