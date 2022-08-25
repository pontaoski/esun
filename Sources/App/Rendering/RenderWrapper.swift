import Vapor
import Foundation

extension Application.Views.Provider {
    public static var wrappedLeaf: Self {
        .init {
            $0.views.use {
                WrappedRenderer(inner: $0.leaf.renderer)
            }
        }
    }
}

struct AppData: Codable {
    var user: User?
    var environment: String

    internal init(from req: Request) async throws {
        self.user = req.auth.get()
        try await self.user?.$customer.load(on: req.db)
        self.environment = req.application.environment.name
    }
}

struct NoData: Codable { }

struct WrappedRenderer: ViewRenderer {
    let inner: ViewRenderer

    struct Wrapper: ViewRenderer {
        let inner: ViewRenderer
        let request: Request

        struct Merged<T>: Encodable where T: Encodable {
            var data: T
            var app: AppData
        }

        func `for`(_ request: Request) -> ViewRenderer {
            return self
        }

        func render<E>(_ name: String, _ context: E) -> EventLoopFuture<View> where E : Encodable {
            let promise = self.request.eventLoop.makePromise(of: View.self)
            promise.completeWithTask {
                let merged = Merged(
                    data: context,
                    app: try await AppData(from: self.request)
                )

                return try await self.inner.render(name, merged)
            }
            return promise.futureResult
        }
    }

    func `for`(_ request: Request) -> ViewRenderer {
        return Wrapper(inner: inner.for(request), request: request)
    }

    func render<E>(_ name: String, _ context: E) -> EventLoopFuture<View> where E : Encodable {
        return inner.render(name, context)
    }
}
