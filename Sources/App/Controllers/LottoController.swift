import Fluent
import Vapor

struct LottoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("lotto")
        group.post("create", use: createLotto)
        group.get(":lotto", use: getInformation)
        group.post(":lotto", "buy-ticket", use: buyTicket)
    }
    struct CreateLottoResponse: Content {
        let lotto: Lotto
    }
    func createLotto(on req: Request) async throws -> CreateLottoResponse {
        struct CreateLottoRequest: Content {
            let title: String
            let description: String
            let slug: String
            let ticketPrice: Int
            let maxTicketsPerCustomer: Int
            let houseCut: Float
        }
        let user = try req.auth.require(User.self)
        let wants = try req.content.decode(CreateLottoRequest.self)

        let lotto = Lotto(
            creator: user.customer,
            ticketPrice: wants.ticketPrice,
            maxTicketsPerCustomer: wants.maxTicketsPerCustomer,
            houseCut: wants.houseCut,
            title: wants.title,
            slug: wants.slug,
            description: wants.description
        )
        try await lotto.save(on: req.db)

        return CreateLottoResponse(lotto: lotto)
    }
    struct GetInformationResponse: Content {
        let lotto: Lotto
        let tickets: [LottoTicket]
    }
    func getInformation(on req: Request) async throws -> GetInformationResponse {
        let user = try req.auth.require(User.self)
        let slug = req.parameters.get(":lotto")!
        guard let lotto = try await Lotto.query(on: req.db).filter(\.$slug == slug).first() else {
            throw Abort(.notFound)
        }
        if user.customer.id! != lotto.$creator.id {
            return GetInformationResponse(lotto: lotto, tickets: [])
        }
        let tickets = try await lotto.$involved.query(on: req.db).all()
        return GetInformationResponse(lotto: lotto, tickets: tickets)
    }
    struct BuyTicketResponse: Content {
    }
    func buyTicket(on req: Request) async throws -> BuyTicketResponse {
        let user = try req.auth.require(User.self)
        let slug = req.parameters.get(":lotto")!
        guard let lotto = try await Lotto.query(on: req.db).filter(\.$slug == slug).first() else {
            throw Abort(.notFound)
        }
        try await lotto.sellTicket(to: user.customer, on: req)
        return BuyTicketResponse()
    }
}