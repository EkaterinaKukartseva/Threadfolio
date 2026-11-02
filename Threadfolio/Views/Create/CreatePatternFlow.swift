//
//  CreatePatternFlow.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData

/// Черновик новой схемы, который заполняется по шагам мастера.
@Observable
final class PatternDraft {
    
    nonisolated enum Source { case blank, image }

    var source: Source = .blank
    var craft: Craft = .crochet
    var imageData: Data? {
        didSet { chartArea = Self.wholeImage }
    }
    /// Область фото с сеткой схемы, в долях изображения.
    var chartArea = wholeImage
    var name = ""
    var columns = 20
    var rows = 20
    var showColumnNumbers = true
    var showRowNumbers = true
    var rowDirection: RowDirection = .bottomToTop
    var columnDirection: ColumnDirection = .leftToRight
    /// Перенести цвета фото в фон клеток (для жаккарда и вышивки).
    var sampleImageColors = false
    /// Сколько цветов в схеме на фото. В вышивке это нитки: канва считается отдельно.
    var colorCount = 8

    static let sizeRange = 2...150
    static let colorRange = 2...30
    static let wholeImage = CGRect(x: 0, y: 0, width: 1, height: 1)

    func makePattern() -> Pattern {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let colors = sampledColors()
        let pattern = Pattern(name: trimmed.isEmpty ? String(localized: "New Chart") : trimmed,
                              craft: craft, columns: columns, rows: rows,
                              showColumnNumbers: showColumnNumbers, showRowNumbers: showRowNumbers,
                              rowDirection: rowDirection, columnDirection: columnDirection,
                              imageData: storedImageData(sampled: colors != nil), cells: colors.map(cells))
        if let colors {
            // Схема уже в клетках: фото выключено, а цвета доступны в палитре редактора.
            pattern.showImage = false
            pattern.customColors = Array(Set(colors))
        }
        return pattern
    }

    private func sampledColors() -> [Color.Resolved]? {
        guard sampleImageColors, let imageData else { return nil }
        return ImageSupport.chartColors(
            from: imageData, area: chartArea, columns: columns, rows: rows,
            colorCount: craft == .crossStitch ? colorCount + 1 : colorCount
        )
    }

    private func storedImageData(sampled: Bool) -> Data? {
        guard sampled, let imageData else { return imageData }
        return ImageSupport.croppedData(from: imageData, area: chartArea) ?? imageData
    }

    /// Цвет переносится заливкой клетки, значки на фото не распознаются.
    /// В вышивке самый светлый цвет считается канвой, такие клетки остаются пустыми.
    private func cells(from colors: [Color.Resolved]) -> [Cell] {
        let fabric = craft == .crossStitch
            ? Set(colors).max { $0.red + $0.green + $0.blue < $1.red + $1.green + $1.blue }
            : nil
        return colors.map { color in
            color == fabric ? .empty : Cell(background: .custom(color))
        }
    }
}

struct CreatePatternFlow: View {
    
    var onCreate: (Pattern) -> Void
    @State private var draft = PatternDraft()

    var body: some View {
        NavigationStack {
            CreatePatternView(draft: draft, onCreate: onCreate)
        }
        .tint(.accentDark)
    }
}

#if DEBUG
#Preview("Create Flow") {
    CreatePatternFlow { _ in }
        .modelContainer(for: Pattern.self, inMemory: true)
}
#endif
