import Fluent
import Vapor

struct LottoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("lotto")
        group.post("create", use: createLotto)
        group.get("my", use: myLottos)
        group.get(":lotto", use: getInformation)
        group.post(":lotto", "buy-ticket", use: buyTicket)
        group.post(":lotto", "roll-winner", use: rollWinner)
    }
    struct MyLottosResponse: Content {
        let lottos: Page<Lotto>
    }
    func myLottos(on req: Request) async throws -> MyLottosResponse {
        let user = try req.auth.require(User.self)
        let lottos = try await Lotto.query(on: req.db).filter(\.$creator.$id == user.customer.id!).paginate(for: req)
        return MyLottosResponse(lottos: lottos)
    }
    struct RollWinner: Content {
        let who: Customer
    }
    func rollWinner(on req: Request) async throws -> RollWinner {
        let user = try req.auth.require(User.self)
        let slug = req.parameters.get("lotto")!
        guard let lotto = try await Lotto.query(on: req.db).filter(\.$slug == slug).first() else {
            throw Abort(.notFound)
        }
        guard user.customer.id! == lotto.$creator.id else {
            throw Abort(.forbidden)
        }
        let tickets = try await lotto.$involved.query(on: req.db).all()
        guard let winning = tickets.randomElement() else {
            throw Abort(.forbidden) // TODO: better error code
        }
        lotto.$winner.id = winning.$buyer.id
        try await winning.$buyer.load(on: req.db)
        try await winning.buyer.$user.load(on: req.db)
        try await lotto.save(on: req.db)
        return RollWinner(who: winning.buyer)
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
        let slug = req.parameters.get("lotto")!
        guard let lotto = try await Lotto.query(on: req.db).filter(\.$slug == slug).first() else {
            throw Abort(.notFound)
        }
        if user.customer.id! != lotto.$creator.id {
            let tickets = try await lotto.$involved.query(on: req.db).filter(\.$buyer.$id == user.customer.id!).all()
            return GetInformationResponse(lotto: lotto, tickets: tickets)
        }
        let tickets = try await lotto.$involved.query(on: req.db).all()
        return GetInformationResponse(lotto: lotto, tickets: tickets)
    }
    struct BuyTicketResponse: Content {
    }
    func buyTicket(on req: Request) async throws -> BuyTicketResponse {
        let user = try req.auth.require(User.self)
        let slug = req.parameters.get("lotto")!
        guard let lotto = try await Lotto.query(on: req.db).filter(\.$slug == slug).first() else {
            throw Abort(.notFound)
        }
        try await lotto.sellTicket(to: user.customer, on: req)
        return BuyTicketResponse()
    }
}