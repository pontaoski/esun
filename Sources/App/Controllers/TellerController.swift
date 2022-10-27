import Fluent
import Vapor

struct RoleMiddleware: AsyncMiddleware {
    let role: SiteRole

    init(atLeast role: SiteRole) {
        self.role = role
    }
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let user: User = try request.auth.require()
        guard user.role >= role else {
            throw Abort(.forbidden)
        }

        return try await next.respond(to: request)
    }
}

struct TellerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let grouped = routes.grouped(RoleMiddleware(atLeast: .teller))

        grouped.post("accounts", ":username", "teller", "adjust-balance") { request -> Response in
            let user: User = try request.auth.require()
            try await user.$customer.load(on: request.db)
            guard let them: User = try await User.get(for: request.parameters.get("username")!, on: request) else {
                throw Abort(.notFound)
            }
            struct Data: Content {
                let ironAmount: Int
                let diamondAmount: Int
            }
            let data = try request.content.decode(Data.self)

            return try await request.db.transaction { db in
                them.customer.ironBalance += data.ironAmount
                them.customer.diamondBalance += data.diamondAmount
                try await them.customer.save(on: db)
                try await AuditLogEntry.logAdjustment(teller: user.customer, to: them.customer, iron: data.ironAmount, diamonds: data.diamondAmount, on: db)

                return Response(status: .ok)
            }
        }
    }
}
