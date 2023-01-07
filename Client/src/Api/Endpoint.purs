module Api.Endpoint where

import Prelude hiding ((/))

import Data.Either (note)
import Data.Generic.Rep (class Generic)
import Data.Lottoname (Lottoname)
import Data.Lottoname as Lottoname
import Data.Maybe (Maybe)
import Data.Shopname (Shopname)
import Data.Shopname as Shopname
import Data.Username (Username)
import Data.Username as Username
import Routing.Duplex (RouteDuplex', as, int, optional, root, segment)
import Routing.Duplex.Generic (noArgs, sum)
import Routing.Duplex.Generic.Syntax ((/), (?))

type Pagination =
    { page :: Maybe Int
    , per :: Maybe Int
    }

data Endpoint
    = Account Username
    | Me
    | AuditLog Username Pagination
    | Shops Username Pagination
    | TransferMoney
    | CreateDepositCode
    | CreateWithdrawalCode
    | UseDepositCode
    | UseWithdrawalCode
    | TellerAdjustBalance Username
    | Shop Shopname
    | CreateShop
    | Items Shopname Pagination
    | CreateItem Shopname
    | CreateLottery
    | MyLotteries
    | GetLotto Lottoname
    | BuyLottoTicket Lottoname
    | RollWinner Lottoname

derive instance genericEndpoint :: Generic Endpoint _

uname :: RouteDuplex' String -> RouteDuplex' Username
uname = as Username.toString (Username.parse >>> note "Bad username")

sname :: RouteDuplex' String -> RouteDuplex' Shopname
sname = as Shopname.toString (Shopname.parse >>> note "Bad shopname")

lname :: RouteDuplex' String -> RouteDuplex' Lottoname
lname = as Lottoname.toString (Lottoname.parse >>> note "Bad lottoname")

endpointCodec :: RouteDuplex' Endpoint
endpointCodec = root $ sum
    { "Account": "accounts" / uname segment
    , "Me": "accounts" / "me" / noArgs
    , "AuditLog": "accounts" / uname segment / "audit-log" ?
        { page: optional <<< int
        , per: optional <<< int
        }
    , "Shops": "accounts" / uname segment / "shops" ?
        { page: optional <<< int
        , per: optional <<< int
        }
    , "TransferMoney": "accounts" / "transfer-money" / noArgs
    , "CreateDepositCode": "accounts" / "create-deposit-code" / noArgs
    , "CreateWithdrawalCode": "teller" / "create-withdrawal-code" / noArgs
    , "TellerAdjustBalance": ("accounts" / uname segment / "teller") / "adjust-balance"
    , "Shop": "shops" / sname segment
    , "CreateShop": "shops" / "create" / noArgs
    , "UseDepositCode": "accounts" / "use-deposit-code" / noArgs
    , "UseWithdrawalCode": "accounts" / "use-withdrawal-code" / noArgs
    , "Items": "shops" / sname segment / "items" ?
        { page: optional <<< int
        , per: optional <<< int
        }
    , "CreateItem": "shops" / sname segment / "items"
    , "CreateLottery": "lotto" / "create" / noArgs
    , "MyLotteries": "lotto" / "my" / noArgs
    , "GetLotto": "lotto" / lname segment
    , "BuyLottoTicket": "lotto" / lname segment / "buy-ticket"
    , "RollWinner": "lotto" / lname segment / "roll-winner"
    }
