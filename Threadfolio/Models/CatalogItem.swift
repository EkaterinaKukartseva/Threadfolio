//
//  CatalogItem.swift
//  Threadfolio
//
//  Created by Ekaterina on 02.11.2026.
//

import SwiftUI

/// Готовая бесплатная схема из каталога. Клетки заданы строками:
/// символ строки — ключ в `legend`, символ без записи в легенде — пустая клетка.
nonisolated struct CatalogItem: Identifiable {

    /// Постоянный идентификатор: хранится в добавленных схемах, менять его нельзя.
    let id: String
    let name: String
    let craft: Craft
    let rows: [String]
    let legend: [Character: Cell]

    var columnCount: Int { rows.first?.count ?? 0 }

    var cells: [Cell] {
        rows.flatMap { row in row.map { legend[$0] ?? .empty } }
    }

    /// Новая схема с содержимым позиции каталога.
    func makePattern() -> Pattern {
        let pattern = Pattern(name: name, craft: craft, columns: columnCount, rows: rows.count, cells: cells)
        pattern.catalogItemID = id
        pattern.customColors = Array(Set(legend.values.compactMap(\.customColor)))
        return pattern
    }
}

extension CatalogItem {

    /// Демо-схемы. Схемы для публикации должны быть своими или с правом на использование.
    static let all = [flyAgaric, heart, snowflake, flower, star, diamond]

    private static func cross(_ color: PaletteColor) -> Cell {
        Cell(symbol: .fullCross, color: .palette(color))
    }

    private static func thread(_ red: Float, _ green: Float, _ blue: Float) -> Cell {
        Cell(symbol: .fullCross, color: .custom(Color.Resolved(red: red, green: green, blue: blue)))
    }

    private static let flyAgaric = CatalogItem(
        id: "crossstitch-fly-agaric",
        name: String(localized: "Fly Agaric"),
        craft: .crossStitch,
        rows: [
            "...........................",
            "..........LLRRRDD..........",
            ".......LLLLRRRRRWDDD.......",
            "......LLLWRRRRRWWWDDD......",
            ".....LLLWWWRRRRRWRDDDD.....",
            "....LLLLLWRRRRRRRRDDDDD....",
            "...LLLLLLRRRWWWRRRRDWDDD...",
            "..LLLWLLRRRWWWWWRRRWWWMMM..",
            "..LLWWWLRRRWWWWWRRRDWDDMM..",
            "..LLLWLLRRRWWWWWRRRDDDDMM..",
            ".LLLLLLLRRRRWWWRRRWRDDDMMM.",
            ".RRRRRRRWRRRRRRRRWWWDDDWMM.",
            ".DDWDDDWWWDDDDDDDDWDDDDMMM.",
            ".DDDDDDDWDDDDDDDDDDDDDDMMM.",
            ".DDDDDDDDDDDDDDDDDDDDDDDMM.",
            "....CSCSCSCSCSCSCSCSCSC....",
            ".......SSSSSSSSSSSSS.......",
            "..........CCCCCSS..........",
            "..........CCCCCSS..........",
            "........WWWWWWWWWWW........",
            ".........SWSWSWSWS.........",
            "..........CCCCCSS..........",
            "..........CCCCCSS..........",
            "..........CCCCCSS....G.....",
            "........GCCCCCCCSS...G.....",
            "...G....GCCCCCCCCSSG.G.....",
            "...G..GCGCCCCCCCCCSG.G..G..",
            "...G..GCGCCCCCCCCCSG.G..G..",
            "..HGHHGHHGHHGHHGHHGHHGHHG..",
            "..HHHHHHHHHHHHHHHHHHHHHHH..",
            "...........................",
        ],
        legend: [
            "L": thread(0.89, 0.33, 0.27),
            "R": thread(0.78, 0.15, 0.15),
            "D": thread(0.62, 0.09, 0.12),
            "M": thread(0.42, 0.06, 0.10),
            "W": thread(0.96, 0.90, 0.78),
            "C": thread(0.86, 0.74, 0.58),
            "S": thread(0.62, 0.50, 0.40),
            "G": thread(0.45, 0.62, 0.30),
            "H": thread(0.24, 0.42, 0.22),
        ]
    )

    private static let heart = CatalogItem(
        id: "crochet-heart",
        name: String(localized: "Little Heart"),
        craft: .crochet,
        rows: [
            ".............",
            "...XX...XX...",
            "..XXXX.XXXX..",
            ".XXXXXXXXXXX.",
            ".XXXXXXXXXXX.",
            "..XXXXXXXXX..",
            "...XXXXXXX...",
            "....XXXXX....",
            ".....XXX.....",
            "......X......",
            ".............",
        ],
        legend: ["X": Cell(symbol: .singleCrochet, color: .palette(.pink))]
    )

    private static let snowflake = CatalogItem(
        id: "crossstitch-snowflake",
        name: String(localized: "Snowflake"),
        craft: .crossStitch,
        rows: [
            "...........",
            ".....B.....",
            "...B.B.B...",
            "....BBB....",
            ".B...B...B.",
            ".BBBBBBBBB.",
            ".B...B...B.",
            "....BBB....",
            "...B.B.B...",
            ".....B.....",
            "...........",
        ],
        legend: ["B": cross(.blue)]
    )

    private static let flower = CatalogItem(
        id: "crossstitch-flower",
        name: String(localized: "Meadow Flower"),
        craft: .crossStitch,
        rows: [
            ".............",
            "...PPP.PPP...",
            "..PPPPPPPPP..",
            "..PPPPOPPPP..",
            "...PPPPPPP...",
            "....PPPPP....",
            "......G......",
            "..GG..G..GG..",
            "...GG.G.GG...",
            ".....GGG.....",
            "......G......",
            ".............",
        ],
        legend: ["P": cross(.pink), "G": cross(.green), "O": cross(.beige)]
    )

    private static let star = CatalogItem(
        id: "crossstitch-star",
        name: String(localized: "Star"),
        craft: .crossStitch,
        rows: [
            ".............",
            "......Y......",
            ".....YYY.....",
            ".....YYY.....",
            ".YYYYYYYYYYY.",
            "...YYYYYYY...",
            "....YYYYY....",
            "...YYYYYYY...",
            "...YYY.YYY...",
            "..YY.....YY..",
            ".............",
        ],
        legend: ["Y": cross(.beige)]
    )

    private static let diamond = CatalogItem(
        id: "knitting-diamond",
        name: String(localized: "Purl Diamond"),
        craft: .knitting,
        rows: [
            ".............",
            "......P......",
            ".....PPP.....",
            "....PP.PP....",
            "...PP...PP...",
            "..PP.....PP..",
            "...PP...PP...",
            "....PP.PP....",
            ".....PPP.....",
            "......P......",
            ".............",
        ],
        legend: [".": Cell(symbol: .knit), "P": Cell(symbol: .purl)]
    )
}

private extension Cell {

    nonisolated var customColor: Color.Resolved? {
        if case .custom(let resolved) = color { resolved } else { nil }
    }
}
