import Fluent
import FluentSQLiteDriver
import Leaf
import Vapor

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

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.databases.middleware.use(AuditLogEntry.Validator())

    app.middleware.use(app.sessions.middleware)
    app.middleware.use(User.sessionAuthenticator())
    app.sessions.use(.fluent)

    app.migrations.add(SessionRecord.migration)
    app.migrations.add(CreateUser())
    app.migrations.add(CreateAuditLog())

    app.views.use(.wrappedLeaf)

    app.leaf.tags["uuidCorrection"] = UUIDCorrection()
    app.leaf.tags["customerLink"] = CustomerRenderer()

    // register routes
    try routes(app)
}
