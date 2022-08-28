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
            }
            return try await req.view.render("shops/shop", ShopPage(shop: shop))
        }
    }
}
