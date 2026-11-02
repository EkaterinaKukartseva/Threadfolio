//
//  SupportMail.swift
//  Threadfolio
//
//  Created by Ekaterina on 02.11.2026.
//

import Foundation

/// Письмо разработчику: ссылка `mailto:` с темой и сведениями о приложении и устройстве.
/// Пользователь видит всё это в черновике письма перед отправкой.
nonisolated enum SupportMail {

    static let address = "threadfolio.support@gmail.com"

    static func url(appVersion: String, system: String, device: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        components.queryItems = [
            URLQueryItem(name: "subject", value: String(localized: "Threadfolio feedback")),
            URLQueryItem(name: "body", value: "\n\n---\nThreadfolio \(appVersion)\niOS \(system)\n\(device)"),
        ]
        return components.url
    }

    static var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// Идентификатор модели, например `iPhone17,1`.
    static var deviceModel: String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { bytes in
            String(bytes: bytes.prefix { $0 != 0 }, encoding: .utf8) ?? ""
        }
    }
}
