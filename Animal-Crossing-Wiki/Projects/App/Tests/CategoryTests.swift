//
//  CategoryTests.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2025/01/01.
//

import XCTest
@testable import ACNH_wiki

final class CategoryTests: XCTestCase {

    // MARK: - Raw Value Tests

    func test_Category_RawValues_ShouldMatchExpectedStrings() {
        XCTAssertEqual(Category.fishes.rawValue, "Fishes")
        XCTAssertEqual(Category.seaCreatures.rawValue, "Sea Creatures")
        XCTAssertEqual(Category.bugs.rawValue, "Bugs")
        XCTAssertEqual(Category.fossils.rawValue, "Fossils")
        XCTAssertEqual(Category.art.rawValue, "Art")
        XCTAssertEqual(Category.housewares.rawValue, "Housewares")
        XCTAssertEqual(Category.miscellaneous.rawValue, "Miscellaneous")
        XCTAssertEqual(Category.wallMounted.rawValue, "Wall mounted")
        XCTAssertEqual(Category.wallpaper.rawValue, "Wallpaper")
        XCTAssertEqual(Category.floors.rawValue, "Floors")
        XCTAssertEqual(Category.rugs.rawValue, "Rugs")
        XCTAssertEqual(Category.other.rawValue, "Other")
        XCTAssertEqual(Category.ceilingDecor.rawValue, "Ceiling Decor")
        XCTAssertEqual(Category.recipes.rawValue, "Recipes")
        XCTAssertEqual(Category.songs.rawValue, "Songs")
        XCTAssertEqual(Category.photos.rawValue, "Photos")
        XCTAssertEqual(Category.fencing.rawValue, "Fencing")
        XCTAssertEqual(Category.tops.rawValue, "Tops")
        XCTAssertEqual(Category.bottoms.rawValue, "Bottoms")
        XCTAssertEqual(Category.dressUp.rawValue, "Dress-Up")
        XCTAssertEqual(Category.headwear.rawValue, "Headwear")
        XCTAssertEqual(Category.accessories.rawValue, "Accessories")
        XCTAssertEqual(Category.socks.rawValue, "Socks")
        XCTAssertEqual(Category.shoes.rawValue, "Shoes")
        XCTAssertEqual(Category.bags.rawValue, "Bags")
        XCTAssertEqual(Category.umbrellas.rawValue, "Umbrellas")
        XCTAssertEqual(Category.wetSuit.rawValue, "Wet Suit")
        XCTAssertEqual(Category.reactions.rawValue, "Reactions")
        XCTAssertEqual(Category.gyroids.rawValue, "Gyroids")
        XCTAssertEqual(Category.tools.rawValue, "Tools")
        XCTAssertEqual(Category.villager.rawValue, "Villager")
        XCTAssertEqual(Category.npc.rawValue, "NPC")
    }

    // MARK: - Icon Name Tests

    func test_IconName_ForCritters_ShouldReturnCorrectIcons() {
        XCTAssertEqual(Category.bugs.iconName, "Ins13")
        XCTAssertEqual(Category.fishes.iconName, "Fish6")
        XCTAssertEqual(Category.seaCreatures.iconName, "div25")
    }

    func test_IconName_ForMuseumItems_ShouldReturnCorrectIcons() {
        XCTAssertEqual(Category.fossils.iconName, "icon-fossil")
        XCTAssertEqual(Category.art.iconName, "icon-board")
    }

    func test_IconName_ForFurniture_ShouldReturnCorrectIcons() {
        XCTAssertEqual(Category.housewares.iconName, "icon-housewares")
        XCTAssertEqual(Category.miscellaneous.iconName, "icon-miscellaneous")
        XCTAssertEqual(Category.wallMounted.iconName, "icon-wallmounted")
        XCTAssertEqual(Category.wallpaper.iconName, "icon-wallpaper")
        XCTAssertEqual(Category.floors.iconName, "icon-floor")
        XCTAssertEqual(Category.rugs.iconName, "icon-rug")
        XCTAssertEqual(Category.other.iconName, "icon-leaf")
        XCTAssertEqual(Category.ceilingDecor.iconName, "icon-ceiling")
    }

    func test_IconName_ForClothing_ShouldReturnCorrectIcons() {
        XCTAssertEqual(Category.tops.iconName, "icon-tops")
        XCTAssertEqual(Category.bottoms.iconName, "icon-pant")
        XCTAssertEqual(Category.dressUp.iconName, "icon-dress")
        XCTAssertEqual(Category.headwear.iconName, "icon-helm")
        XCTAssertEqual(Category.accessories.iconName, "icon-glasses")
        XCTAssertEqual(Category.socks.iconName, "icon-socks")
        XCTAssertEqual(Category.shoes.iconName, "icon-shoes")
        XCTAssertEqual(Category.bags.iconName, "icon-bag")
        XCTAssertEqual(Category.umbrellas.iconName, "icon-umbrella")
        XCTAssertEqual(Category.wetSuit.iconName, "icon-wetsuit")
    }

    func test_IconName_ForAnimals_ShouldReturnCorrectIcons() {
        XCTAssertEqual(Category.villager.iconName, "icon-raymond")
        XCTAssertEqual(Category.npc.iconName, "icon-kk")
    }

    // MARK: - Progress Icon Name Tests

    func test_ProgressIconName_ForCritters_ShouldReturnDifferentFromIconName() {
        XCTAssertEqual(Category.bugs.progressIconName, "Ins1")
        XCTAssertEqual(Category.seaCreatures.progressIconName, "div11")
        // fishes uses same icon
        XCTAssertEqual(Category.fishes.progressIconName, "Fish6")
    }

    // MARK: - Static Category Lists Tests

    func test_Items_ShouldContainAllItemCategories() {
        let items = Category.items()

        XCTAssertTrue(items.contains(.fishes))
        XCTAssertTrue(items.contains(.seaCreatures))
        XCTAssertTrue(items.contains(.bugs))
        XCTAssertTrue(items.contains(.fossils))
        XCTAssertTrue(items.contains(.art))
        XCTAssertTrue(items.contains(.tools))
        XCTAssertTrue(items.contains(.housewares))
        XCTAssertTrue(items.contains(.gyroids))

        // Should NOT contain animal categories
        XCTAssertFalse(items.contains(.villager))
        XCTAssertFalse(items.contains(.npc))
    }

    func test_Progress_ShouldContainOnlyMuseumProgressCategories() {
        let progress = Category.progress()

        XCTAssertEqual(progress.count, 5)
        XCTAssertTrue(progress.contains(.fishes))
        XCTAssertTrue(progress.contains(.bugs))
        XCTAssertTrue(progress.contains(.seaCreatures))
        XCTAssertTrue(progress.contains(.fossils))
        XCTAssertTrue(progress.contains(.art))
    }

    func test_Critters_ShouldContainOnlyCritterCategories() {
        let critters = Category.critters

        XCTAssertEqual(critters.count, 3)
        XCTAssertTrue(critters.contains(.fishes))
        XCTAssertTrue(critters.contains(.seaCreatures))
        XCTAssertTrue(critters.contains(.bugs))
    }

    func test_Furniture_ShouldNotContainCrittersOrMuseumItems() {
        let furniture = Category.furniture()

        XCTAssertFalse(furniture.contains(.fishes))
        XCTAssertFalse(furniture.contains(.seaCreatures))
        XCTAssertFalse(furniture.contains(.bugs))
        XCTAssertFalse(furniture.contains(.fossils))
        XCTAssertFalse(furniture.contains(.art))

        XCTAssertTrue(furniture.contains(.housewares))
        XCTAssertTrue(furniture.contains(.tools))
        XCTAssertTrue(furniture.contains(.gyroids))
    }

    func test_Animals_ShouldContainOnlyAnimalCategories() {
        let animals = Category.animals()

        XCTAssertEqual(animals.count, 2)
        XCTAssertTrue(animals.contains(.npc))
        XCTAssertTrue(animals.contains(.villager))
    }

    // MARK: - Comparable Tests

    func test_Comparable_FishesShouldBeLessThanSeaCreatures() {
        XCTAssertTrue(Category.fishes < Category.seaCreatures)
    }

    func test_Comparable_BugsShouldBeGreaterThanSeaCreatures() {
        XCTAssertTrue(Category.bugs > Category.seaCreatures)
    }

    func test_Comparable_SortedCrittersOrder() {
        let critters: [Category] = [.bugs, .fishes, .seaCreatures]
        let sorted = critters.sorted()

        XCTAssertEqual(sorted, [.fishes, .seaCreatures, .bugs])
    }

    func test_Equatable_SameCategoriesShouldBeEqual() {
        XCTAssertEqual(Category.fishes, Category.fishes)
        XCTAssertEqual(Category.bugs, Category.bugs)
    }

    func test_Equatable_DifferentCategoriesShouldNotBeEqual() {
        XCTAssertNotEqual(Category.fishes, Category.bugs)
    }

    // MARK: - CaseIterable Tests

    func test_AllCases_ShouldContainAllCategories() {
        XCTAssertEqual(Category.allCases.count, 32)
    }
}
