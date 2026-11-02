//
//  AppStoreReview.swift
//  Threadfolio
//
//  Created by Ekaterina on 02.11.2026.
//

import Foundation

/// Ссылка на написание отзыва в App Store.
nonisolated enum AppStoreReview {

    /// Apple ID приложения из App Store Connect. Пока его нет, пункт в профиле скрыт.
    static let appID: String? = nil

    static var url: URL? {
        appID.flatMap(url(appID:))
    }

    static func url(appID: String) -> URL? {
        URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")
    }
}
