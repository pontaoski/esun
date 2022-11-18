module Data.Route where

import Prelude hiding ((/))

import Api.Endpoint (Pagination, uname)
import Data.Either (Either, note)
import Data.Generic.Rep (class Generic)
import Data.Show.Generic (genericShow)
import Data.Token (Token(..))
import Data.UUID as UUID
import Data.Username (Username)
import Routing.Duplex (RouteDuplex', as, int, optional, root, segment, string)
import Routing.Duplex.Generic (noArgs, sum)
import Routing.Duplex.Generic.Syntax ((/), (?))

data Route
    = Home
    | User Username
    | AuthCallback Token
    | AuthRequired AuthRoute

data AuthRoute 
    = CreateDepositCode
    | DepositCodeCreated String
    | AuditLog Username Pagination
    | TransferFunds Username

derive instance genericRoute :: Generic Route _
derive instance eqRoute :: Eq Route
derive instance ordRoute :: Ord Route
instance showRoute :: Show Route where
    show = genericShow

derive instance genericAuthRoute :: Generic AuthRoute _
derive instance eqAuthRoute :: Eq AuthRoute
derive instance ordAuthRoute :: Ord AuthRoute
instance showAuthRoute :: Show AuthRoute where
    show = genericShow

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
    , "AuditLog": "accounts" / uname segment / "audit-log" ?
        { page: optional <<< int
        , per: optional <<< int
        }
    , "TransferFunds": "accounts" / uname segment / "transfer-funds"
    }

routeCodec :: RouteDuplex' Route
routeCodec = root $ sum
    { "Home": noArgs
    , "User": "accounts" / uname segment
    , "AuthCallback": "auth" / "callback" / token segment
    , "AuthRequired": authRouteCodec
    }
