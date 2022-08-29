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
        routes.get("@cart") { req -> View in
            let cart = Cart.for(req)
            var items: [ShopListing] = []
            for item in cart.items {
                if let found = try await ShopListing.find(item, on: req.db) {
                    items.append(found)
                }
            }
            struct CartPage: Codable {
                let items: [ShopListing]
            }
            return try await req.view.render("shops/cart", CartPage(items: items))
        }
        routes.get("@cart", "items", "add") { req -> Response in
            guard let item = try? req.query.get(UUID.self, at: "item") else {
                throw Abort(.badRequest)
            }
            let comeFrom = req.headers["Referer"].first
            try Cart.for(req).with { $0.items.append(item) }.save(to: req)
            return req.redirect(to: comeFrom ?? "/")
        }
        routes.post("@cart", "items", "add") { req -> TurboView in
            guard let item = try? req.query.get(UUID.self, at: "item") else {
                throw Abort(.badRequest)
            }
            try Cart.for(req).with { $0.items.append(item) }.save(to: req)
            return try await TurboView(from: req.view.render("shops/turbo-cart-badge", NoData()))
        }
        let group = routes.grouped("shops").grouped(AlwaysTrailingSlashMiddleware())
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
