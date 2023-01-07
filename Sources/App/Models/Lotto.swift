import Fluent

final class Lotto: Model {
    static let schema = "lottos"

    @ID(key: .id)
    var id: UUID?

    @Children(for: \.$lotto)
    var involved: [LottoTicket]

    @OptionalParent(key: "winner_id")
    var winner: Customer?

    @Parent(key: "creator_id")
    var creator: Customer

    @Field(key: "ticket_price")
    var ticketPrice: Int

    @Field(key: "max_tickets_per_customer")
    var maxTicketsPerCustomer: Int

    @Field(key: "house_cut")
    var houseCut: Float

    @Field(key: "title")
    var title: String

    @Field(key: "description")
    var description: String

    @Field(key: "slug")
    var slug: String

    init() {
    }

    init(
        creator: Customer,
        ticketPrice: Int,
        maxTicketsPerCustomer: Int,
        houseCut: Float,
        title: String,
        slug: String,
        description: String
    ) {
        self.$creator.id = creator.id!
        self.ticketPrice = ticketPrice
        self.maxTicketsPerCustomer = maxTicketsPerCustomer
        self.houseCut = houseCut
        self.title = title
        self.slug = slug
        self.description = description
    }
}

final class LottoTicket: Model {
    static let schema = "lotto_tickets"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "lotto_id")
    var lotto: Lotto

    @Parent(key: "buyer_id")
    var buyer: Customer

    init() {
    }
}
