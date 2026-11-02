//
//  ChartAreaView.swift
//  Threadfolio
//
//  Created by Ekaterina on 02.11.2026.
//

import SwiftUI

/// Рамка на фото: пользователь совмещает её с сеткой готовой схемы.
/// Сетка рамки показывает будущие клетки, каждая десятая линия толще — как в журналах.
struct ChartAreaView: View {

    private enum Corner: CaseIterable, Identifiable {

        case topLeft, topRight, bottomLeft, bottomRight

        var id: Self { self }
        var isLeft: Bool { self == .topLeft || self == .bottomLeft }
        var isTop: Bool { self == .topLeft || self == .topRight }
    }

    private static let minimumSide: CGFloat = 0.05

    @Bindable var draft: PatternDraft
    @State private var detectionFailed = false

    var body: some View {
        VStack(spacing: 14) {
            Text("Drag the corners so the frame matches the chart grid, then detect its size.")
                .font(.caption)
                .foregroundStyle(.secondaryText)
                .multilineTextAlignment(.center)
            if let image = ImageSupport.image(from: draft.imageData) {
                image.resizable().scaledToFit()
                    .overlay {
                        GeometryReader { proxy in
                            frame(in: proxy.size)
                        }
                    }
            }
            Text(detectionFailed ? "Could not detect the grid. Set the size manually." : "Grid: \(draft.columns) × \(draft.rows)")
                .font(.subheadline)
                .foregroundStyle(.ink)
            Button("Detect grid size", action: detectGrid)
                .buttonStyle(PrimaryButtonStyle())
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.background)
        .inlineNavigationTitle("Chart Area")
    }

    private func detectGrid() {
        guard let imageData = draft.imageData,
              let size = ImageSupport.gridSize(from: imageData, area: draft.chartArea),
              PatternDraft.sizeRange.contains(size.columns), PatternDraft.sizeRange.contains(size.rows) else {
            detectionFailed = true
            return
        }
        detectionFailed = false
        draft.columns = size.columns
        draft.rows = size.rows
    }

    private func frame(in size: CGSize) -> some View {
        let area = draft.chartArea
        let rect = CGRect(x: area.minX * size.width, y: area.minY * size.height,
                          width: area.width * size.width, height: area.height * size.height)
        return ZStack {
            Canvas { context, canvasSize in
                var outside = Path(CGRect(origin: .zero, size: canvasSize))
                outside.addRect(rect)
                context.fill(outside, with: .color(.black.opacity(0.4)), style: FillStyle(eoFill: true))
                drawGrid(&context, in: rect)
            }
            ForEach(Corner.allCases) { corner in
                Circle()
                    .fill(Color.accentDark)
                    .frame(width: 18, height: 18)
                    .overlay { Circle().strokeBorder(.white, lineWidth: 2) }
                    .frame(width: 44, height: 44)
                    .contentShape(.circle)
                    .position(x: corner.isLeft ? rect.minX : rect.maxX, y: corner.isTop ? rect.minY : rect.maxY)
                    .gesture(DragGesture(coordinateSpace: .named("chartArea")).onChanged { value in
                        move(corner, to: value.location, in: size)
                    })
            }
        }
        .coordinateSpace(.named("chartArea"))
    }

    private func drawGrid(_ context: inout GraphicsContext, in rect: CGRect) {
        let stepX = rect.width / CGFloat(draft.columns), stepY = rect.height / CGFloat(draft.rows)
        var thin = Path(), bold = Path()
        for column in 0...draft.columns {
            let x = rect.minX + CGFloat(column) * stepX
            var line = Path()
            line.move(to: CGPoint(x: x, y: rect.minY))
            line.addLine(to: CGPoint(x: x, y: rect.maxY))
            if column % 10 == 0 { bold.addPath(line) } else { thin.addPath(line) }
        }
        for row in 0...draft.rows {
            let y = rect.minY + CGFloat(row) * stepY
            var line = Path()
            line.move(to: CGPoint(x: rect.minX, y: y))
            line.addLine(to: CGPoint(x: rect.maxX, y: y))
            if row % 10 == 0 { bold.addPath(line) } else { thin.addPath(line) }
        }
        context.stroke(thin, with: .color(Color.accentDark.opacity(0.35)), lineWidth: 0.5)
        context.stroke(bold, with: .color(Color.accentDark), lineWidth: 1.5)
    }

    private func move(_ corner: Corner, to location: CGPoint, in size: CGSize) {
        let x = min(max(location.x / size.width, 0), 1)
        let y = min(max(location.y / size.height, 0), 1)
        var left = draft.chartArea.minX, right = draft.chartArea.maxX
        var top = draft.chartArea.minY, bottom = draft.chartArea.maxY
        if corner.isLeft { left = min(x, right - Self.minimumSide) } else { right = max(x, left + Self.minimumSide) }
        if corner.isTop { top = min(y, bottom - Self.minimumSide) } else { bottom = max(y, top + Self.minimumSide) }
        draft.chartArea = CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }
}

#if DEBUG
#Preview("Chart Area") {
    NavigationStack {
        ChartAreaView(draft: PatternDraft())
    }
}
#endif
