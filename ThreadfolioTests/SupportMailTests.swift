//
//  SupportMailTests.swift
//  ThreadfolioTests
//
//  Created by Ekaterina on 02.11.2026.
//

import Foundation
import Testing
@testable import Threadfolio

struct SupportMailTests {

    @Test func linkContainsAddressAndDeviceInfo() throws {
        let url = try #require(SupportMail.url(appVersion: "1.0 (1)", system: "18.0.0", device: "iPhone17,1"))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let body = components.queryItems?.first { $0.name == "body" }?.value

        #expect(components.scheme == "mailto")
        #expect(components.path == SupportMail.address)
        #expect(components.queryItems?.contains { $0.name == "subject" } == true)
        #expect(body?.contains("Threadfolio 1.0 (1)") == true)
        #expect(body?.contains("iOS 18.0.0") == true)
        #expect(body?.contains("iPhone17,1") == true)
    }

    @Test func deviceModelIsNotEmpty() {
        #expect(!SupportMail.deviceModel.isEmpty)
    }

    @Test func privacyPolicyFollowsInterfaceLanguage() {
        #expect(PrivacyPolicy.url(language: "ru")?.lastPathComponent == "privacy-ru.html")
        #expect(PrivacyPolicy.url(language: "en")?.lastPathComponent == "privacy.html")
    }

    @Test func reviewLinkOpensWriteReviewPage() {
        let url = AppStoreReview.url(appID: "1234567890")
        #expect(url?.absoluteString == "https://apps.apple.com/app/id1234567890?action=write-review")
    }
}
