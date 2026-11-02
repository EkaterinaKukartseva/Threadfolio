//
//  CatalogView.swift
//  Threadfolio
//
//  Created by Ekaterina on 02.11.2026.
//

import SwiftData
import SwiftUI

/// Каталог бесплатных схем: добавленная схема становится копией в библиотеке.
struct CatalogView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppRouter.self) private var router
    @Query private var patterns: [Pattern]

    private var gridColumns: [GridItem] {
        let isRegular = horizontalSizeClass == .regular
        return [GridItem(.adaptive(minimum: isRegular ? 230 : 150, maximum: isRegular ? 340 : 220), spacing: isRegular ? 20 : 14)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Catalog")
                        .font(.system(.largeTitle, design: .serif))
                        .foregroundStyle(.ink)
                    Text("Charts to add to your library.")
                        .font(.subheadline)
                        .foregroundStyle(.secondaryText)
                }
                .padding(.top, 12)

                LazyVGrid(columns: gridColumns, spacing: 18) {
                    ForEach(CatalogItem.all) { item in
                        CatalogCard(item: item, added: addedPattern(for: item)) {
                            modelContext.insert(item.makePattern())
                        } onOpen: { pattern in
                            router.open(pattern)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.background)
        #if os(iOS)
        .toolbarVisibility(.hidden, for: .navigationBar)
        #endif
    }

    private func addedPattern(for item: CatalogItem) -> Pattern? {
        patterns.first { $0.catalogItemID == item.id }
    }
}

private struct CatalogCard: View {

    let item: CatalogItem
    let added: Pattern?
    var onAdd: () -> Void
    var onOpen: (Pattern) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PatternThumbnail(pattern: item.makePattern())
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.cardBorder) }

            Text(item.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.ink)
                .lineLimit(1)
            Text("\(item.craft.title) · \(item.columnCount)×\(item.rows.count)")
                .font(.caption)
                .foregroundStyle(.secondaryText)

            if let added {
                Button("Open") { onOpen(added) }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("catalogOpen-\(item.id)")
            } else {
                Button("Add", action: onAdd)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("catalogAdd-\(item.id)")
            }
        }
    }
}

#if DEBUG
#Preview("Catalog") {
    NavigationStack {
        CatalogView()
    }
    .environment(AppRouter())
    .modelContainer(SampleData.previewContainer)
}
#endif
