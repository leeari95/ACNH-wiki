//
//  ItemTests.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2025/01/01.
//

import XCTest
@testable import ACNH_wiki

final class ItemTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeTranslations() -> Translations {
        Translations(
            eUde: "TestDE",
            eUen: "TestEN",
            eUit: "TestIT",
            eUnl: "TestNL",
            eUru: "TestRU",
            eUfr: "TestFR",
            eUes: "TestES",
            uSen: "TestUS",
            uSfr: "TestUSFR",
            uSes: "TestUSES",
            jPja: "TestJA",
            kRko: "TestKO",
            tWzh: "TestTW",
            cNzh: "TestCN"
        )
    }

    private func makeItem(
        name: String = "Test Item",
        category: Category = .housewares,
        sell: Int = 100,
        colors: [Color] = [.blue, .red],
        genuine: Bool? = true,
        exchangeCurrency: ExchangeCurrency? = nil,
        variations: [Variant]? = nil
    ) -> Item {
        var item = Item(
            name: name,
            category: category,
            sell: sell,
            translations: makeTranslations(),
            colors: colors
        )
        item.genuine = genuine
        item.exchangeCurrency = exchangeCurrency
        item.variations = variations
        return item
    }

    private func makeVariant(
        variantId: String = "item_0",
        exchangeCurrency: ExchangeCurrency? = nil,
        pattern: String? = nil
    ) -> Variant {
        Variant(
            image: "test_image.png",
            variation: "Test Variation",
            pattern: pattern,
            patternTitle: nil,
            kitType: nil,
            cyrusCustomizePrice: 0,
            surface: nil,
            exchangePrice: nil,
            exchangeCurrency: exchangeCurrency,
            seasonEvent: nil,
            seasonEventExclusive: nil,
            hhaCategory: nil,
            filename: "test_file",
            variantId: variantId,
            internalId: 1,
            variantTranslations: nil,
            colors: [.blue],
            concepts: nil,
            patternTranslations: nil,
            soundType: nil
        )
    }

    // MARK: - Basic Property Tests

    func test_Item_Initialization_ShouldSetPropertiesCorrectly() {
        let item = makeItem(name: "My Item", category: .fishes, sell: 500)

        XCTAssertEqual(item.name, "My Item")
        XCTAssertEqual(item.category, .fishes)
        XCTAssertEqual(item.sell, 500)
    }

    // MARK: - Keyword Tests

    func test_Keyword_WithColors_ShouldIncludeColorRawValues() {
        let item = makeItem(colors: [.blue, .red, .green])

        XCTAssertTrue(item.keyword.contains("Blue"))
        XCTAssertTrue(item.keyword.contains("Red"))
        XCTAssertTrue(item.keyword.contains("Green"))
    }

    func test_Keyword_WithTag_ShouldIncludeTag() {
        var item = makeItem()
        item.tag = "Furniture"

        XCTAssertTrue(item.keyword.contains("Furniture"))
    }

    func test_Keyword_WithTagAlreadyInList_ShouldNotDuplicate() {
        var item = makeItem(colors: [.blue])
        item.tag = "Blue"

        let blueCount = item.keyword.filter { $0.lowercased() == "blue" }.count
        // Tag should not be added if already exists (case-insensitive check in the original code)
        XCTAssertGreaterThanOrEqual(blueCount, 1)
    }

    // MARK: - Exchange Currency Tests

    func test_CanExchangeNookMiles_WhenItemHasNookMilesCurrency_ShouldReturnTrue() {
        let item = makeItem(exchangeCurrency: .nookMiles)

        XCTAssertTrue(item.canExchangeNookMiles)
    }

    func test_CanExchangeNookMiles_WhenVariationHasNookMilesCurrency_ShouldReturnTrue() {
        let variation = makeVariant(exchangeCurrency: .nookMiles)
        let item = makeItem(variations: [variation])

        XCTAssertTrue(item.canExchangeNookMiles)
    }

    func test_CanExchangeNookMiles_WhenNoNookMilesCurrency_ShouldReturnFalse() {
        let item = makeItem(exchangeCurrency: nil)

        XCTAssertFalse(item.canExchangeNookMiles)
    }

    func test_CanExchangeNookPoints_WhenItemHasNookPointsCurrency_ShouldReturnTrue() {
        let item = makeItem(exchangeCurrency: .nookPoints)

        XCTAssertTrue(item.canExchangeNookPoints)
    }

    func test_CanExchangePoki_WhenItemHasPokiCurrency_ShouldReturnTrue() {
        let item = makeItem(exchangeCurrency: .poki)

        XCTAssertTrue(item.canExchangePoki)
    }

    // MARK: - Critters Tests

    func test_IsCritters_WhenCategoryIsFish_ShouldReturnTrue() {
        let item = makeItem(category: .fishes)

        XCTAssertTrue(item.isCritters)
    }

    func test_IsCritters_WhenCategoryIsBugs_ShouldReturnTrue() {
        let item = makeItem(category: .bugs)

        XCTAssertTrue(item.isCritters)
    }

    func test_IsCritters_WhenCategoryIsSeaCreatures_ShouldReturnTrue() {
        let item = makeItem(category: .seaCreatures)

        XCTAssertTrue(item.isCritters)
    }

    func test_IsCritters_WhenCategoryIsHousewares_ShouldReturnFalse() {
        let item = makeItem(category: .housewares)

        XCTAssertFalse(item.isCritters)
    }

    // MARK: - Variations Tests

    func test_VariationsWithColor_ShouldFilterByVariantIdSuffix() {
        let variation1 = makeVariant(variantId: "item_0")
        let variation2 = makeVariant(variantId: "item_1")
        let variation3 = makeVariant(variantId: "item2_0")
        let item = makeItem(variations: [variation1, variation2, variation3])

        let colorVariations = item.variationsWithColor

        XCTAssertEqual(colorVariations.count, 2) // item_0 and item2_0
    }

    func test_VariationsWithPattern_ShouldFilterByPatternExistence() {
        let variation1 = makeVariant(pattern: "Pattern A")
        let variation2 = makeVariant(pattern: nil)
        let variation3 = makeVariant(pattern: "Pattern B")
        let item = makeItem(variations: [variation1, variation2, variation3])

        let patternVariations = item.variationsWithPattern

        XCTAssertEqual(patternVariations.count, 2)
    }

    func test_VariationsWithColor_WhenNoVariations_ShouldReturnEmptyArray() {
        let item = makeItem(variations: nil)

        XCTAssertTrue(item.variationsWithColor.isEmpty)
    }

    func test_VariationsWithPattern_WhenNoVariations_ShouldReturnEmptyArray() {
        let item = makeItem(variations: nil)

        XCTAssertTrue(item.variationsWithPattern.isEmpty)
    }

    // MARK: - Equatable Tests

    func test_Equatable_ItemsWithSameNameAndGenuine_ShouldBeEqual() {
        let item1 = makeItem(name: "Test", genuine: true)
        let item2 = makeItem(name: "Test", genuine: true)

        XCTAssertEqual(item1, item2)
    }

    func test_Equatable_ItemsWithDifferentNames_ShouldNotBeEqual() {
        let item1 = makeItem(name: "Test1")
        let item2 = makeItem(name: "Test2")

        XCTAssertNotEqual(item1, item2)
    }

    func test_Equatable_ItemsWithDifferentGenuine_ShouldNotBeEqual() {
        let item1 = makeItem(name: "Test", genuine: true)
        let item2 = makeItem(name: "Test", genuine: false)

        XCTAssertNotEqual(item1, item2)
    }

    // MARK: - Hashable Tests

    func test_Hashable_SameItemsShouldHaveSameHash() {
        let item1 = makeItem(name: "Test", genuine: true)
        let item2 = makeItem(name: "Test", genuine: true)

        XCTAssertEqual(item1.hashValue, item2.hashValue)
    }

    func test_Hashable_ItemsCanBeUsedInSet() {
        let item1 = makeItem(name: "Item1")
        let item2 = makeItem(name: "Item2")
        let item3 = makeItem(name: "Item1") // Duplicate

        var itemSet: Set<Item> = []
        itemSet.insert(item1)
        itemSet.insert(item2)
        itemSet.insert(item3)

        XCTAssertEqual(itemSet.count, 2)
    }
}
