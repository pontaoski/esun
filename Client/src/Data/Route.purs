module Data.Route where

import Prelude hiding ((/))

import Data.Either (Either, note)
import Data.Generic.Rep (class Generic)
import Data.Token (Token(..))
import Data.UUID as UUID
import Routing.Duplex (RouteDuplex', as, root, segment, string)
import Routing.Duplex.Generic (noArgs, sum)
import Routing.Duplex.Generic.Syntax ((/))

data Route
    = Home
    | AuthCallback Token
    | AuthRequired AuthRoute

data AuthRoute 
    = CreateDepositCode
    | DepositCodeCreated String

derive instance genericRoute :: Generic Route _
derive instance eqRoute :: Eq Route
derive instance ordRoute :: Ord Route

derive instance genericAuthRoute :: Generic AuthRoute _
derive instance eqAuthRoute :: Eq AuthRoute
derive instance ordAuthRoute :: Ord AuthRoute

token :: RouteDuplex' String -> RouteDuplex' Token
token = as print parse
    where
        print :: Token -> String
        print (Token t) =
            UUID.toString t

        parse :: String -> Either String Token
        parse =
            (UUID.parseUUID >>> (<$>) Token) >>> note "Bad token"

authRouteCodec :: RouteDuplex' AuthRoute
authRouteCodec = sum
    { "CreateDepositCode": "create-deposit-code" / noArgs
    , "DepositCodeCreated": "deposit-code-created" / string segment
    }

routeCodec :: RouteDuplex' Route
routeCodec = root $ sum
    { "Home": noArgs
    , "AuthCallback": "auth" / "callback" / token segment
    , "AuthRequired": authRouteCodec
    }
