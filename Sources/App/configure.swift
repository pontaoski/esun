import Fluent
import FluentSQLiteDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    app.middleware.use(app.sessions.middleware)
    app.middleware.use(User.sessionAuthenticator())
    app.sessions.use(.fluent)

    app.migrations.add(SessionRecord.migration)
    app.migrations.add(CreateUser())

    app.views.use(.wrappedLeaf)

    app.leaf.tags["uuidCorrection"] = UUIDCorrection()

    // register routes
    try routes(app)
}
