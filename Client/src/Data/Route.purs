module Data.Route where

import Prelude hiding ((/))

import Data.Token (Token(..))
import Data.Either (Either, note)
import Data.Generic.Rep (class Generic)
import Data.UUID as UUID
import Routing.Duplex (RouteDuplex', root, segment, as)
import Routing.Duplex.Generic (noArgs, sum)
import Routing.Duplex.Generic.Syntax ((/))

data Route
    = Home
    | AuthCallback Token

derive instance genericRoute :: Generic Route _
derive instance eqRoute :: Eq Route
derive instance ordRoute :: Ord Route

token :: RouteDuplex' String -> RouteDuplex' Token
token = as print parse
    where
        print :: Token -> String
        print (Token t) =
            UUID.toString t

        parse :: String -> Either String Token
        parse =
            (UUID.parseUUID >>> (<$>) Token) >>> note "Bad token"

routeCodec :: RouteDuplex' Route
routeCodec = root $ sum
    { "Home": noArgs
    , "AuthCallback": "auth" / "callback" / token segment
    }
