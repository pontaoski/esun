import Fluent
import FluentSQLiteDriver
import Leaf
import Vapor
import Redis

struct AlwaysTrailingSlashMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if !request.url.path.hasSuffix("/") {
            var new = request.url
            new.path += "/"
            return request.redirect(to: new.string)
        }
        return try await next.respond(to: request)
    }
}

struct UserAuthenticator: AsyncRequestAuthenticator {
    func authenticate(request req: Request) async throws {
        if let token = req.cookies.all["AuthToken"],
            let uuid = UUID(token.string),
            let user = try await User.find(uuid, on: req.db) {
                try await user.$customer.load(on: req.db)
                req.auth.login(user)
            }

        let token = req.headers[.authorization]
        if token.count > 0,
            let uuid = UUID(token[0]),
            let user = try await User.find(uuid, on: req.db) {
                try await user.$customer.load(on: req.db)
                req.auth.login(user)
            }
    }
}

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.databases.middleware.use(AuditLogEntry.Validator())
    app.databases.middleware.use(ShopListing.Validator())

    app.redis.configuration = try RedisConfiguration(hostname: "localhost")

    app.middleware.use(app.sessions.middleware)
    app.middleware.use(UserAuthenticator())
    app.sessions.use(.fluent)

    app.migrations.add(SessionRecord.migration)
    app.migrations.add(CreateUser())
    app.migrations.add(CreateAuditLog())
    app.migrations.add(CreateRole())
    app.migrations.add(CreateDepositCode())
    app.migrations.add(CreateShop())

    app.views.use(.wrappedLeaf)

    app.leaf.tags["uuidCorrection"] = UUIDCorrection()
    app.leaf.tags["customerLink"] = CustomerRenderer()

    // register routes
    try routes(app)
}
