import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("accounts")
        group.grouped(AlwaysTrailingSlashMiddleware()).get(":username", use: account)
        group.get("@me") { req -> Response in
            let who: User = try req.auth.require()
            return req.redirect(to: "/accounts/\(who.username)")
        }
    }
    struct UserpageData: Codable {
        let user: User?
    }
    func account(req: Request) async throws -> View {
        let username = req.parameters.get("username")!
        let user = try await User.get(for: username, on: req)
        return try await req.view.render("userpage", UserpageData(user: user))
    }
}
