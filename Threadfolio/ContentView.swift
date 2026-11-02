//
//  ContentView.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import StoreKit
import SwiftUI
import SwiftData

/// Навигация приложения: вкладки, стек библиотеки и окно создания схемы.
@Observable
final class AppRouter {
    
    enum Tab: Hashable { case patterns, catalog, legend, profile }

    var selectedTab: Tab = .patterns
    var libraryPath = NavigationPath()
    var isCreating = false

    func open(_ pattern: Pattern) {
        selectedTab = .patterns
        libraryPath = NavigationPath()
        libraryPath.append(pattern)
    }
}

struct ContentView: View {
    
    @State private var router = AppRouter()
    @AppStorage(OnboardingView.storageKey) private var hasSeenOnboarding = false
    @AppStorage("createdChartsCount") private var createdChartsCount = 0
    @Environment(\.requestReview) private var requestReview
    /// Окно оценки ждёт, пока закроется мастер создания схемы.
    @State private var isReviewDue = false

    private static let chartsBeforeReview = 3

    var body: some View {
        TabView(selection: $router.selectedTab) {
            SwiftUI.Tab("Charts", systemImage: "house", value: AppRouter.Tab.patterns) {
                NavigationStack(path: $router.libraryPath) {
                    LibraryView()
                        .navigationDestination(for: Pattern.self) { pattern in
                            EditorView(pattern: pattern)
                        }
                }
            }
            SwiftUI.Tab("Catalog", systemImage: "square.grid.2x2", value: AppRouter.Tab.catalog) {
                NavigationStack { CatalogView() }
            }
            SwiftUI.Tab("Symbols", systemImage: "book.closed", value: AppRouter.Tab.legend) {
                NavigationStack { LegendView() }
            }
            SwiftUI.Tab("Profile", systemImage: "person", value: AppRouter.Tab.profile) {
                NavigationStack { ProfileView() }
            }
        }
        .tint(Color.accentDark)
        .environment(router)
        .sheet(isPresented: $router.isCreating, onDismiss: requestReviewIfNeeded) {
            CreatePatternFlow { pattern in
                router.isCreating = false
                router.open(pattern)
                createdChartsCount += 1
                isReviewDue = createdChartsCount == Self.chartsBeforeReview
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasSeenOnboarding && !ThreadfolioApp.isUITesting },
            set: { if !$0 { hasSeenOnboarding = true } }
        )) {
            OnboardingView()
        }
    }

    private func requestReviewIfNeeded() {
        guard isReviewDue else { return }
        isReviewDue = false
        if !ThreadfolioApp.isUITesting { requestReview() }
    }
}

#if DEBUG
#Preview("With Charts") {
    ContentView()
        .modelContainer(SampleData.previewContainer)
}

#Preview("Empty Library") {
    ContentView()
        .modelContainer(for: Pattern.self, inMemory: true)
}
#endif
