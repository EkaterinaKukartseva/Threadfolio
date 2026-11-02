//
//  ProfileView.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftData
import SwiftUI

struct ProfileView: View {
    
    @Query private var patterns: [Pattern]
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system
    @Environment(\.openURL) private var openURL
    /// Почта не настроена: показываем адрес, чтобы его можно было скопировать.
    @State private var isShowingMailAddress = false

    var body: some View {
        List {
            Section("Appearance") {
                Picker(selection: $theme) {
                    ForEach(AppTheme.allCases) { Text($0.title).tag($0) }
                } label: {
                    Label("Theme", systemImage: "circle.lefthalf.filled").foregroundStyle(Color.ink)
                }
                .pickerStyle(.menu)
                .tint(Color.secondaryText)
            }
            Section("My Charts") {
                statRow("Total", patterns.count, icon: "square.grid.2x2")
                statRow("Crochet", patterns.filter { $0.craft == .crochet }.count, icon: Craft.crochet.icon)
                statRow("Knitting", patterns.filter { $0.craft == .knitting }.count, icon: Craft.knitting.icon)
                statRow("Cross-stitch", patterns.filter { $0.craft == .crossStitch }.count, icon: Craft.crossStitch.icon)
                statRow("Favorites", patterns.filter(\.isFavorite).count, icon: "heart")
            }
            Section("Support") {
                Button(action: contactDeveloper) {
                    Label("Contact the Developer", systemImage: "envelope").foregroundStyle(Color.ink)
                }
                if let reviewURL = AppStoreReview.url {
                    Link(destination: reviewURL) {
                        Label("Write a Review", systemImage: "star").foregroundStyle(Color.ink)
                    }
                }
                if let privacyURL = PrivacyPolicy.url {
                    Link(destination: privacyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised").foregroundStyle(Color.ink)
                    }
                }
            }
            Section {
                LabeledContent {
                    Text(verbatim: appVersion).monospacedDigit()
                } label: {
                    Label("Version", systemImage: "info.circle").foregroundStyle(Color.ink)
                }
            } footer: {
                Text("Charts are stored on this device and saved automatically after every change.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.background)
        .navigationTitle("Profile")
        .alert("Couldn’t open Mail", isPresented: $isShowingMailAddress) {
            Button("Copy Address") { UIPasteboard.general.string = SupportMail.address }
            Button("Close", role: .cancel) {}
        } message: {
            Text("Write to us at \(SupportMail.address)")
        }
    }

    private func contactDeveloper() {
        let mail = SupportMail.url(appVersion: appVersion, system: SupportMail.systemVersion, device: SupportMail.deviceModel)
        guard let mail else {
            isShowingMailAddress = true
            return
        }
        openURL(mail) { accepted in
            if !accepted { isShowingMailAddress = true }
        }
    }

    /// «1.0 (1)» — версия из App Store и номер сборки.
    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func statRow(_ title: LocalizedStringKey, _ value: Int, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon).foregroundStyle(Color.ink)
            Spacer()
            Text(verbatim: "\(value)").foregroundStyle(Color.secondaryText).monospacedDigit()
        }
    }
}

#if DEBUG
#Preview("Profile") {
    NavigationStack { ProfileView() }
        .modelContainer(SampleData.previewContainer)
}
#endif
