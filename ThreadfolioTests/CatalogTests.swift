//
//  CatalogTests.swift
//  ThreadfolioTests
//
//  Created by Ekaterina on 02.11.2026.
//

import Testing
@testable import Threadfolio

@MainActor
struct CatalogTests {

    @Test func identifiersAreUnique() {
        let ids = CatalogItem.all.map { item in item.id }
        #expect(Set(ids).count == ids.count)
    }

    @Test func rowsHaveEqualLength() {
        for item in CatalogItem.all {
            #expect(item.rows.allSatisfy { $0.count == item.columnCount }, "\(item.id)")
        }
    }

    @Test func patternKeepsContentAndCatalogID() throws {
        let item = try #require(CatalogItem.all.first)
        let pattern = item.makePattern()
        #expect(pattern.catalogItemID == item.id)
        // Свои цвета после JSON могут отличаться в последнем знаке, поэтому сравниваются символы.
        #expect(pattern.cells.map { $0.symbol } == item.cells.map { $0.symbol })
        #expect(!pattern.customColors.isEmpty)
        #expect(pattern.cells.contains { !$0.isEmpty })
    }

    @Test func duplicateIsNoLongerLinkedToCatalog() throws {
        let item = try #require(CatalogItem.all.first)
        #expect(item.makePattern().duplicate().catalogItemID == nil)
    }
}
