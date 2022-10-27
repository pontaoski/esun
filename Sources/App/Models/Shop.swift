import Foundation
import Fluent
import Vapor

final class Shop: Model, Content {
    static let schema = "shops"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "owner")
    var owner: Customer

    @Children(for: \.$shop)
    var listings: [ShopListing]

    @Field(key: "title")
    var title: String

    @Field(key: "description")
    var description: String

    @Field(key: "slug")
    var slug: String

    init() { }
    init(owner: Customer, title: String, description: String, slug: String) {
        self.$owner.id = owner.id!
        self.title = title
        self.description = description
        self.slug = slug
        
    }
}

enum MCData {
    struct Enchantment: Codable {
        let name: String
        let maxLevel: Int
        let category: String
        let exclude: [String]
    }
    struct Item: Codable {
        let name: String
        let enchantCategories: [String]?
    }

    static var items: [Item] {
        try! JSONDecoder().decode([Item].self, from: String(contentsOfFile: "items.json").data(using: .utf8)!)
    }
    static func item(named name: String) -> Item? {
        items.first { $0.name == name }
    }
    static var enchantments: [Enchantment] {
        try! JSONDecoder().decode([Enchantment].self, from: String(contentsOfFile: "enchantments.json").data(using: .utf8)!)
    }
    static func enchantment(named name: String) -> Enchantment? {
        enchantments.first { $0.name == name }
    }
}

final class ShopListing: Model {
    static let schema = "shop_listings"

    struct Validator: AsyncModelMiddleware {
        func create(model: ShopListing, on db: Database, next: AnyAsyncModelResponder) async throws {
            try validate(model)
            return try await next.create(model, on: db)
        }
        func update(model: ShopListing, on db: Database, next: AnyAsyncModelResponder) async throws {
            try validate(model)
            return try await next.update(model, on: db)
        }

        func validateItem(_ model: ShopListing) throws {
            guard model.title == nil, model.description == nil else {
                throw Abort(.badRequest, reason: "item listing can't have custom data")
            }
            guard let item = MCData.item(named: model.item!) else {
                throw Abort(.badRequest, reason: "item listing doesn't match known MC item")
            }
            for enchant in (model.enchants ?? []) {
                guard let enchantData = MCData.enchantment(named: enchant.name) else {
                    throw Abort(.badRequest, reason: "item listing enchant doesn't match known MC item enchant")
                }
                guard (item.enchantCategories ?? []).contains(enchantData.category) else {
                    throw Abort(.badRequest, reason: "item isn't enchantable")
                }
                guard 0 < enchant.level, enchant.level <= enchantData.maxLevel else {
                    throw Abort(.badRequest, reason: "item has bad enchantment level")
                }
            }
        }
        func validateCustom(_ model: ShopListing) throws {
            guard model.item == nil, model.enchants == nil else {
                throw Abort(.badRequest, reason: "custom listing can't have item data")
            }
        }
        func validate(_ model: ShopListing) throws {
            guard model.ironPrice >= 0 || model.diamondPrice >= 0 else {
                throw Abort(.badRequest, reason: "listing needs a non-negative price")
            }
            if let stock = model.stock, stock < 0 {
                throw Abort(.badRequest, reason: "listing can't have negative stock")
            }
            if let quantity = model.quantity, quantity < 0 {
                throw Abort(.badRequest, reason: "listing can't have negative quantity")
            }
            if model.item != nil {
                return try validateItem(model)
            } else if model.title != nil {
                return try validateCustom(model)
            }
            throw Abort(.badRequest, reason: "needs to be an item or a custom listing")
        }
    }

    struct Enchant: Codable {
        let name: String
        let level: Int
    }

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "shop_id")
    var shop: Shop

    @Parent(key: "created_by")
    var createdBy: Customer

    /// this item is a plain MC item, so it has fixed fields
    @OptionalField(key: "item")
    var item: String?

    /// what enchants the item has
    @OptionalField(key: "enchants")
    var enchants: [Enchant]?

    /// this item isn't an MC item, so it has custom stuff
    @OptionalField(key: "title")
    var title: String?

    @OptionalField(key: "description")
    var description: String?

    /// how many you can sell
    @OptionalField(key: "stock")
    var stock: Int?

    /// how many are sold per one stock
    @OptionalField(key: "quantity")
    var quantity: Int?

    @OptionalField(key: "compacted")
    var compacted: Bool?

    @Field(key: "diamond_price")
    var diamondPrice: Int

    @Field(key: "iron_price")
    var ironPrice: Int
}
