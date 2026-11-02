//
//  GridDetector.swift
//  Threadfolio
//
//  Created by Ekaterina on 02.11.2026.
//

import Foundation

/// Находит шаг сетки на фото схемы: линии сетки повторяются с постоянным периодом,
/// и он виден как пик автокорреляции в профиле яркости вдоль стороны изображения.
nonisolated enum GridDetector {

    private static let minimumCell = 4
    /// Рисунок и толстые линии тоже дают пики, но слабее или кратнее шагу клетки.
    private static let relativePeak: Float = 0.5

    /// Шаг сетки в пикселях. `profile` — средняя темнота каждого столбца или ряда пикселей.
    static func period(of profile: [Float]) -> Double? {
        let signal = highPass(profile)
        let maximumLag = signal.count / 3
        guard maximumLag > minimumCell else { return nil }
        let energy = (signal.map { $0 * $0 }).reduce(0, +)
        guard energy > 0 else { return nil }

        var scores = [Float](repeating: 0, count: maximumLag + 2)
        for lag in minimumCell...(maximumLag + 1) {
            var sum: Float = 0
            for index in 0..<(signal.count - lag) { sum += signal[index] * signal[index + lag] }
            scores[lag] = sum / energy
        }
        let peaks = (minimumCell...maximumLag).filter { scores[$0] > scores[$0 - 1] && scores[$0] >= scores[$0 + 1] }
        guard let strongest = peaks.map({ scores[$0] }).max(), strongest > 0.1,
              let lag = peaks.first(where: { scores[$0] >= strongest * relativePeak }) else { return nil }
        return refined(lag, scores: scores)
    }

    /// Дальний кратный пик уточняет дробный шаг: на скане клетка бывает 20,7 пикселя.
    private static func refined(_ lag: Int, scores: [Float]) -> Double {
        let multiple = (scores.count - 2) / lag
        guard multiple > 1 else { return Double(lag) }
        let center = lag * multiple
        let range = max(lag, center - multiple)...min(scores.count - 1, center + multiple)
        let peak = range.max { scores[$0] < scores[$1] } ?? center
        return Double(peak) / Double(multiple)
    }

    /// Убирает плавные перепады рисунка, оставляя тонкие линии.
    private static func highPass(_ profile: [Float]) -> [Float] {
        let radius = 4
        return profile.indices.map { index in
            let range = max(0, index - radius)...min(profile.count - 1, index + radius)
            let mean = profile[range].reduce(0, +) / Float(range.count)
            return max(0, profile[index] - mean)
        }
    }
}
