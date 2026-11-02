//
//  ColorQuantizer.swift
//  Threadfolio
//
//  Created by Ekaterina on 02.11.2026.
//

import Foundation

/// Сводит цвета клеток к небольшой палитре: фото схемы даёт тысячи оттенков,
/// а ниток в ней всего несколько. Метод k-средних в пространстве Lab,
/// где расстояние между цветами близко к тому, как их различает глаз.
nonisolated enum ColorQuantizer {

    struct Result {

        /// Цвета палитры в sRGB.
        let palette: [SIMD3<Float>]
        /// Для каждого входного цвета — номер в `palette`.
        let indices: [Int]
    }

    private static let iterations = 16

    static func quantize(_ colors: [SIMD3<Float>], count: Int) -> Result {
        guard !colors.isEmpty, count > 0 else { return Result(palette: [], indices: []) }
        let points = colors.map(lab)
        var centers = seeds(colors: colors, points: points, count: count)
        var indices = [Int](repeating: 0, count: points.count)

        for _ in 0..<iterations {
            for (i, point) in points.enumerated() {
                indices[i] = nearest(to: point, in: centers)
            }
            var sums = [SIMD3<Float>](repeating: .zero, count: centers.count)
            var sizes = [Float](repeating: 0, count: centers.count)
            for (i, point) in points.enumerated() {
                sums[indices[i]] += point
                sizes[indices[i]] += 1
            }
            for i in centers.indices where sizes[i] > 0 {
                centers[i] = sums[i] / sizes[i]
            }
        }

        // Палитра — средние sRGB по группам; пустые группы отбрасываются.
        var sums = [SIMD3<Float>](repeating: .zero, count: centers.count)
        var sizes = [Float](repeating: 0, count: centers.count)
        for (i, color) in colors.enumerated() {
            indices[i] = nearest(to: points[i], in: centers)
            sums[indices[i]] += color
            sizes[indices[i]] += 1
        }
        var remap = [Int](repeating: 0, count: centers.count)
        var palette: [SIMD3<Float>] = []
        for i in centers.indices where sizes[i] > 0 {
            remap[i] = palette.count
            palette.append(sums[i] / sizes[i])
        }
        return Result(palette: palette, indices: indices.map { remap[$0] })
    }

    /// Начальные центры: каждый следующий — самый далёкий от уже выбранных.
    /// Редкие оттенки (шум скана) в кандидаты не попадают.
    private static func seeds(colors: [SIMD3<Float>], points: [SIMD3<Float>], count: Int) -> [SIMD3<Float>] {
        var bins: [SIMD3<Int32>: Int] = [:]
        let keys = colors.map { SIMD3<Int32>($0 * 15, rounding: .toNearestOrAwayFromZero) }
        for key in keys { bins[key, default: 0] += 1 }
        let minimum = max(2, colors.count / 500)
        var candidates = points.indices.filter { (bins[keys[$0]] ?? 0) >= minimum }.map { points[$0] }
        if candidates.isEmpty { candidates = points }

        var centers = [candidates.max { $0.x < $1.x } ?? candidates[0]]
        while centers.count < count {
            var best: SIMD3<Float>?
            var bestDistance: Float = 0
            for candidate in candidates {
                let distance = centers.map { squaredDistance($0, candidate) }.min() ?? 0
                if distance > bestDistance {
                    bestDistance = distance
                    best = candidate
                }
            }
            guard let best else { break }
            centers.append(best)
        }
        return centers
    }

    private static func nearest(to point: SIMD3<Float>, in centers: [SIMD3<Float>]) -> Int {
        var bestIndex = 0
        var bestDistance = Float.infinity
        for (index, center) in centers.enumerated() {
            let distance = squaredDistance(point, center)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        return bestIndex
    }

    private static func squaredDistance(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        let delta = a - b
        return (delta * delta).sum()
    }

    /// sRGB → CIE Lab (белая точка D65).
    private static func lab(_ color: SIMD3<Float>) -> SIMD3<Float> {
        func linear(_ value: Float) -> Float {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        func curve(_ value: Float) -> Float {
            value > 0.008856 ? cbrt(value) : 7.787 * value + 16 / 116
        }
        let red = linear(color.x), green = linear(color.y), blue = linear(color.z)
        let tristimulusX = curve((0.4124 * red + 0.3576 * green + 0.1805 * blue) / 0.95047)
        let tristimulusY = curve(0.2126 * red + 0.7152 * green + 0.0722 * blue)
        let tristimulusZ = curve((0.0193 * red + 0.1192 * green + 0.9505 * blue) / 1.08883)
        return SIMD3(116 * tristimulusY - 16, 500 * (tristimulusX - tristimulusY), 200 * (tristimulusY - tristimulusZ))
    }
}
