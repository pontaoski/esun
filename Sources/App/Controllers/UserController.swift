import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("accounts")
        group.get("@me", use: me)
    }
    func me(req: Request) async throws -> View {
        return try await req.view.render("test", NoData())
    }
}
