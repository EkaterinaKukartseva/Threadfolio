//
//  OnboardingView.swift
//  Threadfolio
//
//  Created by Ekaterina on 02.11.2026.
//

import SwiftUI

/// Приветственные слайды: показываются один раз, при первом запуске.
struct OnboardingView: View {

    private struct Slide: Identifiable {

        let id: Int
        let icon: String
        let title: LocalizedStringKey
        let message: LocalizedStringKey
    }

    static let storageKey = "hasSeenOnboarding"

    private static let slides = [
        Slide(id: 0, icon: "square.grid.3x3", title: "Your charts in one place",
              message: "Create charts for crochet, knitting and cross-stitch."),
        Slide(id: 1, icon: "photo", title: "Import from a photo",
              message: "Take a picture of a chart, and the app will transfer its grid and colors."),
        Slide(id: 2, icon: "pencil.tip", title: "Draw stitch by stitch",
              message: "Choose a stitch and a color, then tap a cell or drag across the grid."),
        Slide(id: 3, icon: "square.and.arrow.up", title: "Share your work",
              message: "Export a chart with its legend as an image."),
    ]

    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private var isLastPage: Bool { page == Self.slides.count - 1 }

    var body: some View {
        VStack(spacing: 16) {
            Button("Skip") { dismiss() }
                .foregroundStyle(.secondaryText)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .opacity(isLastPage ? 0 : 1)
                .disabled(isLastPage)

            TabView(selection: $page) {
                ForEach(Self.slides) { slide in
                    slideView(slide).tag(slide.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(Self.slides) { slide in
                    Circle()
                        .fill(slide.id == page ? Color.accentDark : Color.cardBorder)
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityHidden(true)

            Button(isLastPage ? "Get Started" : "Next") {
                if isLastPage {
                    dismiss()
                } else {
                    withAnimation { page += 1 }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: 420)
        }
        .padding(20)
        .background(Color.background)
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(spacing: 20) {
            Image(systemName: slide.icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.accent)
                .accessibilityHidden(true)
            Text(slide.title)
                .font(.system(.title, design: .serif))
                .foregroundStyle(.ink)
            Text(slide.message)
                .font(.body)
                .foregroundStyle(.secondaryText)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 480)
        .padding(.horizontal, 12)
    }
}

#if DEBUG
#Preview("Onboarding") {
    OnboardingView()
}
#endif
