import Fluent
import Vapor

struct Cart: Codable {
    var items: [UUID] = []

    func with(_ closure: (inout Cart) -> Void) -> Cart {
        var new = self
        closure(&new)
        return new
    }
    static func `for`(_ request: Request) -> Cart {
        guard let data = request.session.data["cart"] else {
            return Cart()
        }
        return (try? JSONDecoder().decode(Cart.self, from: data.data(using: .utf8)!)) ?? Cart()
    }
    func save(to request: Request) throws {
        let data = try JSONEncoder().encode(self)
        request.session.data["cart"] = String(data: data, encoding: .utf8)
    }
}

struct ShopController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("shops")
        group.get(":shop") { req -> Shop in
            guard let shop = try await Shop.query(on: req.db)
                .filter(\.$slug == req.parameters.get("shop")!)
                .first() else {
                    throw Abort(.notFound)
                }

            return shop
        }
        group.post("create") { req -> Shop in
            let user = try req.auth.require(User.self)
            struct CreateShopRequest: Codable {
                let name: String
                let description: String
                let slug: String
            }
            let wants = try req.content.decode(CreateShopRequest.self)

            let shop = Shop(owner: user.customer, title: wants.name, description: wants.description, slug: wants.slug)
            try await shop.save(on: req.db)

            return shop
        }
        group.get(":shop", "items") { req -> Page<ShopListing> in
            guard let shop = try await Shop.query(on: req.db).filter(\.$slug == req.parameters.get("shop")!).first() else {
                throw Abort(.notFound)
            }
            let listings = try await ShopListing.query(on: req.db).filter(\.$shop.$id == shop.id!).with(\.$createdBy, { item in item.with(\.$user) }).paginate(for: req)
            return listings
        }
        struct ItemResponse: Content {
            let id: UUID
        }
        group.post(":shop", "items") { req -> ItemResponse in
            let user = try req.auth.require(User.self)
            guard let shop = try await Shop.query(on: req.db).filter(\.$slug == req.parameters.get("shop")!).first() else {
                throw Abort(.notFound)
            }
            guard shop.$owner.id == user.customer.id! else {
                throw Abort(.forbidden)
            }
            struct CreateItemRequest: Codable {
                let itemID: String
                let stock: Int
                let enchants: [Int: ShopListing.Enchant]
                var enchantsArray: [ShopListing.Enchant] { enchants.keys.sorted().map { enchants[$0]! }}
                let quantity: Int
                let compacted: Bool
                let diamondPrice: Int
                let ironPrice: Int
            }
            let data = try req.content.decode(CreateItemRequest.self)

            let listing = ShopListing()
            listing.$shop.id = shop.id!
            listing.$createdBy.id = user.customer.id!
            listing.item = data.itemID
            listing.enchants = data.enchantsArray
            listing.stock = data.stock
            listing.quantity = data.quantity
            listing.compacted = data.compacted
            listing.diamondPrice = data.diamondPrice
            listing.ironPrice = data.ironPrice

            try await listing.save(on: req.db)

            return ItemResponse(id: listing.id!)
        }
    }
}
