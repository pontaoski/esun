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

struct CreateItemListingPage: FormPage {
    static let page: String = "shops/create-item-listing"
    static let route: PathComponent = "create-item-listing"

    struct Form: FormData {
        var itemID: String = ""
        var stock: Int = 0
        var enchants: [Int: ShopListing.Enchant] = [:]
        var enchantsArray: [ShopListing.Enchant] { enchants.keys.sorted().map { enchants[$0]! }}
        var quantity: Int = 0
        var compacted: Bool = false
        var diamondPrice: Int = 0
        var ironPrice: Int = 0

        var errors: [String] = []
    }
    typealias Success = Self

    var form: Form
    var enchants: [ShopListing.Enchant]

    static func submit(form data: Form, on req: Request) async throws -> FormPageResponse<CreateItemListingPage, Success> {
        let user: User = try req.auth.require()
        try await user.$customer.load(on: req.db)

        guard let shop = try await Shop.query(on: req.db).filter(\.$slug == req.parameters.get("shop")!).first() else {
            throw Abort(.notFound)
        }
        guard shop.$owner.id == user.customer.id! else {
            throw Abort(.forbidden)
        }

        let listing = ShopListing()
        listing.$shop.id = shop.id!
        listing.$createdBy.id = shop.id!
        listing.item = data.itemID
        listing.enchants = data.enchantsArray
        listing.stock = data.stock
        listing.quantity = data.quantity
        listing.compacted = data.compacted
        listing.diamondPrice = data.diamondPrice
        listing.ironPrice = data.ironPrice

        do {
            try await listing.save(on: req.db)
        } catch let error as Abort where error.status == .badRequest {
            return .form(CreateItemListingPage(form: data.with { $0.errors = [error.reason] }, enchants: data.enchantsArray))
        }

        return .success(CreateItemListingPage(form: data, enchants: data.enchantsArray))
    }

    static func initial(on request: Request) async throws -> CreateItemListingPage {
        return CreateItemListingPage(form: Form(), enchants: [])
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
        CreateItemListingPage.register(to: routes.grouped("shops", ":shop"))
    }
}
