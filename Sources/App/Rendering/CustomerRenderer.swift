import Leaf

struct CustomerRenderer: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
        guard let dict = ctx.parameters[0].dictionary else {
            throw "first parameter of CustomerRenderer is not a dictionary"
        }
        if let data = dict["user"]?.dictionary {
            guard let username = data["username"]?.string else {
                throw "user does not have a username"
            }
            return .string(
                #"""
                <a href="/accounts/\#(username)/" class="linkbutton inline-flex items-baseline space-x-1">
                    <img src="https://crafthead.net/avatar/\#(username)" class="self-center inline aspect-square h-5">
                    <span>\#(username)</span>
                </a>
                """#)
        }
        throw "customer does not have any data to render with"
    }
}
