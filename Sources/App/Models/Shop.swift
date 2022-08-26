import Fluent

final class Shop: Model {
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
}

final class ShopListing: Model {
    static let schema = "shop_listings"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "shop_id")
    var shop: Shop

    @Parent(key: "created_by")
    var createdBy: Customer

    @Field(key: "title")
    var title: String

    @Field(key: "description")
    var description: String

    @OptionalField(key: "stock")
    var stock: Int?

    @OptionalField(key: "quantity")
    var quantity: Int?

    @OptionalField(key: "compacted")
    var compacted: Bool?
}
