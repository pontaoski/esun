import Fluent
import Vapor

// TODO: oauth shenanigans
struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("auth")
        group.get("login", use: login)
    }
    func login(req: Request) async throws -> Response {
        guard let user = try await User.get(for: "OnceDoceTrece", on: req) else {
            throw Abort(.notFound)
        }
        if !user.created {
            user.created = true
            try await user.save(on: req.db)
        }
        req.auth.login(user)
        return req.redirect(to: "/accounts/@me")
    }
}