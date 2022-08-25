import Fluent
import Vapor

protocol FormData: Codable {
    var errors: [String] { get }
    init()
}

extension FormData {
    func with(_ adjust: (inout Self) -> Void) -> Self {
        var new = self
        adjust(&new)
        return new
    }
}

enum FormPageResponse<Page: FormPage, Success: Codable> {
    case form(Page)
    case response(Response)
    case success(Success)
}

protocol FormPage: Codable {
    static var page: String { get }
    static var route: PathComponent { get }

    associatedtype Form: FormData
    associatedtype Success: Codable

    var form: Form { get }

    static func submit(form data: Form, on request: Request) async throws -> FormPageResponse<Self, Success>
    static func initial(on request: Request) async throws -> Self
}

public struct TurboView: AsyncResponseEncodable {
    public var data: ByteBuffer

    public init(from view: View) {
        self.data = view.data
    }

    public func encodeResponse(for request: Request) async throws -> Response {
        let response = Response()
        response.headers.contentType = .init(type: "text", subType: "vnd.turbo-stream.html")
        response.body = .init(buffer: self.data, byteBufferAllocator: request.byteBufferAllocator)
        return response
    }
}

extension HTTPMediaTypePreference {
    var isTurbo: Bool {
        mediaType.type == "text" && mediaType.subType == "vnd.turbo-stream.html"
    }
}

extension Request {
    var isTurbo: Bool {
        headers.accept.contains(where: { $0.isTurbo })
    }
}

extension FormPage {
    static func register(to routes: RoutesBuilder) {
        routes.get(Self.route) { req async throws -> AnyAsyncResponse in
            let initial = try await Self.initial(on: req)
            return .init(try await req.view.render(Self.page + "/index", initial))
        }
        routes.post(Self.route) { req async throws -> AnyAsyncResponse in
            let submitted = try await Self.submit(form: req.content.decode(Self.Form.self), on: req)
            switch submitted {
            case .form(let form):
                if req.isTurbo {
                    return .init(TurboView(from: try await req.view.render(Self.page + "/turbo", form)))
                }
                return .init(try await req.view.render(Self.page + "/index", form))
            case .response(let response):
                return .init(response)
            case .success(let data):
                if req.isTurbo {
                    return .init(TurboView(from: try await req.view.render(Self.page + "/turbo_success", data)))
                }
                return .init(try await req.view.render(Self.page + "/success", data))
            }
        }
    }
}
