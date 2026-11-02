//
//  ImageSupport.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import CoreGraphics
import ImageIO

enum ImageSupport {
    
    static func cgImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        // Сразу учитываем EXIF-поворот и уменьшаем большие фото с камеры.
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2048,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    static func image(from data: Data?) -> Image? {
        guard let data, let cgImage = cgImage(from: data) else { return nil }
        return Image(decorative: cgImage, scale: 1)
    }

    /// Уменьшенная JPEG-копия для хранения в схеме.
    static func compressedData(from data: Data) -> Data? {
        guard let cgImage = cgImage(from: data) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, "public.jpeg" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        return CGImageDestinationFinalize(destination) ? output as Data : nil
    }

    /// Вырезает область фото. `area` — в долях изображения, начало слева сверху.
    static func cropped(_ cgImage: CGImage, to area: CGRect) -> CGImage? {
        let width = CGFloat(cgImage.width), height = CGFloat(cgImage.height)
        return cgImage.cropping(to: CGRect(
            x: area.minX * width, y: area.minY * height,
            width: area.width * width, height: area.height * height
        ).integral)
    }

    /// JPEG с вырезанной областью фото: подложка должна совпадать с клетками схемы.
    static func croppedData(from data: Data, area: CGRect) -> Data? {
        guard let source = cgImage(from: data), let image = cropped(source, to: area) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, "public.jpeg" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        return CGImageDestinationFinalize(destination) ? output as Data : nil
    }

    /// Размер сетки в выбранной области фото: сколько клеток по ширине и высоте.
    static func gridSize(from data: Data, area: CGRect) -> (columns: Int, rows: Int)? {
        guard let source = cgImage(from: data), let image = cropped(source, to: area) else { return nil }
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }

        var columnProfile = [Float](repeating: 0, count: width)
        var rowProfile = [Float](repeating: 0, count: height)
        for y in 0..<height {
            for x in 0..<width {
                let darkness = 255 - Float(pixels[y * width + x])
                columnProfile[x] += darkness
                rowProfile[y] += darkness
            }
        }
        guard let columnStep = GridDetector.period(of: columnProfile.map { $0 / Float(height) }),
              let rowStep = GridDetector.period(of: rowProfile.map { $0 / Float(width) }) else { return nil }
        return (Int((Double(width) / columnStep).rounded()), Int((Double(height) / rowStep).rounded()))
    }

    /// Цвет каждой клетки области фото, сведённый к `colorCount` цветам.
    static func chartColors(from data: Data, area: CGRect, columns: Int, rows: Int, colorCount: Int) -> [Color.Resolved]? {
        guard let source = cgImage(from: data), let image = cropped(source, to: area),
              let samples = cellCenters(of: image, columns: columns, rows: rows) else { return nil }
        let result = ColorQuantizer.quantize(samples, count: colorCount)
        let palette = result.palette.map { Color.Resolved(red: $0.x, green: $0.y, blue: $0.z) }
        return result.indices.map { palette[$0] }
    }

    /// Медиана цвета в середине каждой клетки: линии сетки и шум скана в неё не попадают.
    private static func cellCenters(of image: CGImage, columns: Int, rows: Int) -> [SIMD3<Float>]? {
        guard columns > 0, rows > 0 else { return nil }
        let cellSide = 8, margin = 2
        let width = columns * cellSide, height = rows * cellSide
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }

        var samples: [SIMD3<Float>] = []
        samples.reserveCapacity(columns * rows)
        for row in 0..<rows {
            for column in 0..<columns {
                var channels: [[UInt8]] = [[], [], []]
                for y in (row * cellSide + margin)..<((row + 1) * cellSide - margin) {
                    for x in (column * cellSide + margin)..<((column + 1) * cellSide - margin) {
                        let offset = (y * width + x) * 4
                        for channel in 0..<3 { channels[channel].append(pixels[offset + channel]) }
                    }
                }
                let median = channels.map { Float($0.sorted()[$0.count / 2]) / 255 }
                samples.append(SIMD3(median[0], median[1], median[2]))
            }
        }
        return samples
    }

    /// PNG-файл во временной папке — для «Поделиться».
    static func writePNG(_ cgImage: CGImage, named name: String) -> URL? {
        let safeName = name.components(separatedBy: CharacterSet(charactersIn: "/\\:?*\"<>|")).joined()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeName.isEmpty ? String(localized: "Chart") : safeName)
            .appendingPathExtension("png")
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        return CGImageDestinationFinalize(destination) ? url : nil
    }
}
