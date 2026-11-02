//
//  PhotoImportTests.swift
//  ThreadfolioTests
//
//  Created by Ekaterina on 02.11.2026.
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import Threadfolio

struct ColorQuantizerTests {

    private let red = SIMD3<Float>(0.9, 0.1, 0.1)
    private let blue = SIMD3<Float>(0.1, 0.1, 0.9)

    @Test func noisyShadesCollapseToPalette() {
        let colors = (0..<200).map { index -> SIMD3<Float> in
            let noise = Float(index % 5) * 0.01
            return (index.isMultiple(of: 2) ? red : blue) + SIMD3(repeating: noise)
        }
        let result = ColorQuantizer.quantize(colors, count: 2)
        #expect(result.palette.count == 2)
        #expect(result.indices.count == 200)
        #expect(result.indices[0] == result.indices[2])
        #expect(result.indices[0] != result.indices[1])
    }

    @Test func paletteNeverExceedsDistinctColors() {
        let result = ColorQuantizer.quantize(Array(repeating: red, count: 20), count: 8)
        #expect(result.palette.count == 1)
    }

    @Test func emptyInputGivesEmptyPalette() {
        #expect(ColorQuantizer.quantize([], count: 8).palette.isEmpty)
    }
}

struct GridDetectorTests {

    /// Тёмные линии с шагом `step` и более толстые — каждая десятая.
    private func profile(step: Double, cells: Int) -> [Float] {
        var values = [Float](repeating: 0, count: Int(step * Double(cells)))
        for cell in 0..<cells {
            values[Int(Double(cell) * step)] = cell.isMultiple(of: 10) ? 200 : 80
        }
        return values
    }

    @Test func findsCellStepDespiteBoldLines() throws {
        let period = try #require(GridDetector.period(of: profile(step: 12, cells: 60)))
        #expect(abs(period - 12) < 0.2)
    }

    @Test func keepsFractionalStep() throws {
        let period = try #require(GridDetector.period(of: profile(step: 20.7, cells: 50)))
        #expect(abs(period - 20.7) < 0.2)
    }

    @Test func flatImageHasNoGrid() {
        #expect(GridDetector.period(of: [Float](repeating: 10, count: 300)) == nil)
    }
}

@MainActor
struct PhotoImportTests {

    /// Квадрат 2×2 клетки: левая половина красная, правая белая, между клетками тёмные линии.
    private func chartPhoto() throws -> Data {
        let side = 200
        let context = try #require(CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        context.setFillColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: side / 2, height: side))
        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: side / 2 - 2, y: 0, width: 4, height: side))
        context.fill(CGRect(x: 0, y: side / 2 - 2, width: side, height: 4))
        let image = try #require(context.makeImage())
        let output = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(output, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return output as Data
    }

    private func draft(craft: Craft) throws -> PatternDraft {
        let draft = PatternDraft()
        draft.craft = craft
        draft.imageData = try chartPhoto()
        draft.sampleImageColors = true
        draft.columns = 2
        draft.rows = 2
        draft.colorCount = 2
        return draft
    }

    @Test func crossStitchKeepsColorsWithoutSymbols() throws {
        let pattern = try draft(craft: .crossStitch).makePattern()
        #expect(pattern.cells.allSatisfy { $0.symbol == nil })
        #expect(pattern.cells.map { $0.background != nil } == [true, false, true, false])
        #expect(ThreadUsage.threads(of: pattern).map(\.count) == [2])
        #expect(!pattern.showImage)
        #expect(pattern.customColors.count == 2)
    }

    @Test func knittingKeepsColorsAsFills() throws {
        let pattern = try draft(craft: .knitting).makePattern()
        #expect(pattern.cells.allSatisfy { $0.symbol == nil && $0.background != nil })
        #expect(ThreadUsage.colors(in: pattern.cells).count == 2)
    }

    @Test func newPhotoResetsChartArea() {
        let draft = PatternDraft()
        draft.chartArea = CGRect(x: 0.2, y: 0.2, width: 0.5, height: 0.5)
        draft.imageData = Data([1])
        #expect(draft.chartArea == PatternDraft.wholeImage)
    }
}
