import Fluent
import Vapor

struct ShopController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("shops")
        group.get(":shop") { req -> View in
            guard let shop = try await Shop.query(on: req.db).filter(\.$slug == req.parameters.get("shop")!).first() else {
                throw Abort(.notFound)
            }
            struct ShopPage: Codable {
                let shop: Shop
                let listings: Page<ShopListing>
            }
            let listings = try await ShopListing.query(on: req.db).filter(\.$shop.$id == shop.id!).with(\.$createdBy, { item in item.with(\.$user) }).paginate(for: req)
            return try await req.view.render("shops/shop", ShopPage(shop: shop, listings: listings))
        }
    }
}
