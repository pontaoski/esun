module Api.Request where

import Prelude

import Affjax.RequestBody as RB
import Affjax.RequestHeader (RequestHeader(..))
import Affjax.ResponseFormat (ResponseFormat(..))
import Affjax.ResponseFormat as RF
import Affjax.StatusCode (StatusCode(..))
import Affjax.Web (Request, printError, request)
import Api.Endpoint (Endpoint(..), Pagination, endpointCodec)
import Data.Argonaut.Core (Json)
import Data.AuditLogEntry (AuditLogEntry)
import Data.AuditLogEntry as AuditLogEntry
import Data.Codec as Codec
import Data.Codec.Argonaut (JsonCodec, JsonDecodeError, printJsonDecodeError)
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Record as CAR
import Data.Customer (Customer)
import Data.Customer as Customer
import Data.Either (Either(..))
import Data.Error (Error(..), explain)
import Data.HTTP.Method (Method(..))
import Data.Lotto (Lotto, Lottoname)
import Data.Lotto as Lotto
import Data.Maybe (Maybe(..))
import Data.Page (Page)
import Data.Page as Page
import Data.Profile (MyProfile, Profile)
import Data.Profile as Profile
import Data.Token (Token(..))
import Data.Tuple (Tuple(..))
import Data.UUID as UUID
import Data.Username (Username(..))
import Data.Username as Username
import Effect (Effect)
import Effect.Aff.Class (class MonadAff, liftAff)
import Routing.Duplex (print)
import Web.HTML (window)
import Web.HTML.Window (localStorage)
import Web.Storage.Storage (getItem, removeItem, setItem)

newtype BaseURL = BaseURL String

data RequestMethod
    = Get
    | Post (Maybe Json)
    | Put (Maybe Json)
    | Delete

type RequestOptions =
    { endpoint :: Endpoint
    , method :: RequestMethod
    }

defaultRequest :: BaseURL -> Maybe Token -> RequestOptions -> Request Json
defaultRequest (BaseURL baseUrl) auth { endpoint, method } =
  { method: Left requestMethod
  , url: baseUrl <> print endpointCodec endpoint
  , headers: case auth of
      Nothing -> []
      Just (Token t) -> [ RequestHeader "Authorization" $ UUID.toString t ]
  , content: RB.json <$> body
  , username: Nothing
  , password: Nothing
  , timeout: Nothing
  , withCredentials: false
  , responseFormat: RF.json
  }
  where
  Tuple requestMethod body = case method of
    Get -> Tuple GET Nothing
    Post b -> Tuple POST b
    Put b -> Tuple PUT b
    Delete -> Tuple DELETE Nothing

profileResponseCodec :: forall a. JsonCodec a -> JsonCodec { user :: a }
profileResponseCodec inner =
    CAR.object "Profile response"
        { user: inner
        }

pageResponseCodec :: forall a. JsonCodec a -> JsonCodec { pages :: (Page a) }
pageResponseCodec inner =
    CAR.object "Page response"
        { pages: Page.codec inner
        }

decodeProfileResponse :: forall a. JsonCodec a -> Json -> Either JsonDecodeError { user :: a }
decodeProfileResponse inner user = do
    Codec.decode (profileResponseCodec inner) user

decodePageResponse :: forall a. JsonCodec a -> Json -> Either JsonDecodeError { pages :: (Page a) }
decodePageResponse inner user = do
    Codec.decode (pageResponseCodec inner) user

me :: forall m. MonadAff m => BaseURL -> Token -> m (Either Error MyProfile)
me baseUrl token = do
    res <- liftAff $ request $ defaultRequest baseUrl (Just token) { endpoint: Me, method: Get }
    case res of
        Left e -> pure $ Left $ explain "getting my profile" e
        Right v -> do
            case decodeProfileResponse Profile.profileWithCustomerCodec v.body of
                Left er -> pure $ Left $ explain "parsing my profile response" er
                Right p ->
                    pure $ Right $ {username: p.user.username, id: p.user.id, customer: p.user.customer, created: p.user.created, role: p.user.role, token: token}

account :: forall m. MonadAff m => BaseURL -> Username -> m (Either Error Profile)
account baseUrl username = do
    res <- liftAff $ request $ defaultRequest baseUrl Nothing { endpoint: Account username, method: Get }
    case res of
        Left e -> pure $ Left $ explain "getting account" e
        Right v -> do
            case decodeProfileResponse Profile.profileCodec v.body of
                Left er -> pure $ Left $ explain "parsing audit log response" er
                Right p ->
                    pure $ Right $ {username: p.user.username, created: p.user.created, role: p.user.role, id: p.user.id}

auditLog :: forall m. MonadAff m => BaseURL -> Token -> Username -> Pagination -> m (Either Error (Page AuditLogEntry))
auditLog baseUrl token username pages = do
    res <- liftAff $ request $ defaultRequest baseUrl (Just token) { endpoint: AuditLog username pages, method: Get }
    case res of
        Left e -> pure $ Left $ explain "getting audit log" e
        Right v -> do
            case decodePageResponse AuditLogEntry.codec v.body of
                Left er -> pure $ Left $ explain "parsing audit log response" er
                Right p ->
                    pure $ Right p.pages

transferMoney :: forall m. MonadAff m => BaseURL -> Token -> Username -> Int -> Int -> m (Either Error Unit)
transferMoney baseUrl token username iron diamonds = do
    res <- liftAff $ request $ (defaultRequest baseUrl (Just token)
        { endpoint: TransferMoney
        , method: Post $ Just $ (Codec.encode
            (CAR.object "params"
                { ironAmount: CA.int
                , diamondAmount: CA.int
                , to: Username.codec
                })
            { ironAmount: iron, diamondAmount: diamonds, to: username })
        }) { responseFormat = RF.ignore }
    case res of
        Left e -> pure $ Left $ explain "transferring funds" e
        Right v | v.status == StatusCode 200 -> do
            pure $ Right unit
        Right _ ->
            pure $ Left $ Custom "failed"

currencyAmount :: { iron :: Int, diamonds :: Int } -> Json
currencyAmount { iron, diamonds } =
    Codec.encode (CAR.object "params" { ironAmount: CA.int, diamondAmount: CA.int }) { ironAmount: iron, diamondAmount: diamonds }

createDepositCode :: forall m. MonadAff m => BaseURL -> Token -> { iron :: Int, diamonds :: Int } -> m (Either Error String)
createDepositCode baseUrl token { iron, diamonds } = do
    res <- liftAff $ request $ defaultRequest baseUrl (Just token) { endpoint: CreateDepositCode, method: Post $ Just (Codec.encode (CAR.object "params" { ironAmount: CA.int, diamondAmount: CA.int }) { ironAmount: iron, diamondAmount: diamonds }) }
    case res of
        Left e -> pure $ Left $ explain "creating deposit code" e
        Right v -> do
            case Codec.decode (CAR.object "response" { code: CA.string }) v.body of
                Left er -> pure $ Left $ explain "parsing deposit code response" er
                Right p ->
                    pure $ Right p.code

createWithdrawalCode :: forall m. MonadAff m => BaseURL -> Token -> { password :: String, iron :: Int, diamonds :: Int } -> m (Either Error String)
createWithdrawalCode baseUrl token { password, iron, diamonds } = do
    res <- liftAff $ request $ defaultRequest baseUrl (Just token) { endpoint: CreateWithdrawalCode, method: Post $ Just (Codec.encode (CAR.object "params" { password: CA.string, ironAmount: CA.int, diamondAmount: CA.int }) { password: password, ironAmount: iron, diamondAmount: diamonds }) }
    case res of
        Left e -> pure $ Left $ explain "creating withdrawal code" e
        Right v -> do
            case Codec.decode (CAR.object "response" { code: CA.string }) v.body of
                Left er -> pure $ Left $ explain "parsing withdrawal code response" er
                Right p ->
                    pure $ Right p.code

encodeCodeRequest ∷ String → Json
encodeCodeRequest code =
    Codec.encode (CAR.object "params" { code: CA.string }) { code }

useDepositCode :: forall m. MonadAff m => BaseURL -> Token -> String -> m (Either Error { iron :: Int, diamonds :: Int })
useDepositCode baseUrl token code = do
    res <- liftAff $ request $ defaultRequest baseUrl (Just token) { endpoint: UseDepositCode, method: Post $ Just $ encodeCodeRequest code }
    case res of
        Left e ->
            pure $ Left $ explain "creating deposit code" e
        Right v -> do
            case Codec.decode (CAR.object "response" { ironAmount: CA.int, diamondAmount: CA.int }) v.body of
                Left er ->
                    pure $ Left $ explain "parsing deposit code response" er
                Right { ironAmount, diamondAmount } ->
                    pure $ Right { iron: ironAmount, diamonds: diamondAmount }

useWithdrawalCode :: forall m. MonadAff m => BaseURL -> Token -> String -> m (Either Error { iron :: Int, diamonds :: Int, password :: String })
useWithdrawalCode baseUrl token code = do
    res <- liftAff $ request $ defaultRequest baseUrl (Just token) { endpoint: UseWithdrawalCode, method: Post $ Just $ encodeCodeRequest code }
    case res of
        Left e ->
            pure $ Left $ explain "creating deposit code" e
        Right v -> do
            case Codec.decode (CAR.object "response" { password: CA.string, ironAmount: CA.int, diamondAmount: CA.int }) v.body of
                Left er ->
                    pure $ Left $ explain "parsing deposit code response" er
                Right { ironAmount, diamondAmount, password } ->
                    pure $ Right { iron: ironAmount, diamonds: diamondAmount, password }

adjustBalance :: forall m. MonadAff m => BaseURL -> Token -> Username -> { iron :: Int, diamonds :: Int } -> m (Either Error Unit)
adjustBalance baseUrl token target { iron, diamonds } = do
    res <- liftAff $ request $
        (defaultRequest baseUrl (Just token) { endpoint: TellerAdjustBalance target, method: Post $ Just $ currencyAmount { iron, diamonds } })
        { responseFormat = RF.ignore }
    case res of
        Left e -> pure $ Left $ explain "adjusting balance" e
        Right v | v.status == StatusCode 200 -> do
            pure $ Right unit
        Right _ ->
            pure $ Left $ Custom "failed"

type CreateLottoRequest =
    { title :: String
    , description :: String
    , slug :: String
    , ticketPrice :: Int
    , maxTicketsPerCustomer :: Int
    , houseCut :: Number
    }

createLotto :: forall m. MonadAff m => BaseURL -> Token -> CreateLottoRequest -> m (Either Error Lotto)
createLotto baseUrl token information = do
    let body = Codec.encode (CAR.object "params"
        { title: CA.string
        , description: CA.string
        , slug: CA.string
        , ticketPrice: CA.int
        , maxTicketsPerCustomer: CA.int
        , houseCut: CA.number
        }) information
    res <- liftAff $ request $
        (defaultRequest baseUrl (Just token) { endpoint: CreateLottery, method: Post $ Just body })
    case res of
        Left e ->
            pure $ Left $ explain "creating lotto" e
        Right v ->
            case Codec.decode (CAR.object "response" { lotto: Lotto.codec }) v.body of
                Left er ->
                    pure $ Left $ explain "parsing lotto response" er
                Right { lotto } ->
                    pure $ Right lotto

myLotteries :: forall m. MonadAff m => BaseURL -> Token -> m (Either Error (Page Lotto))
myLotteries baseUrl token = do
    res <- liftAff $ request $
        (defaultRequest baseUrl (Just token) { endpoint: MyLotteries, method: Get })
    case res of
        Left e ->
            pure $ Left $ explain "getting lottos" e
        Right v -> case Codec.decode (CAR.object "response" { lottos: pageResponseCodec Lotto.codec }) v.body of
            Left er ->
                pure $ Left $ explain "parsing lotto response" er
            Right { lottos } ->
                pure $ Right lottos

rollLotteryWinner :: forall m. MonadAff m => BaseURL -> Token -> Lottoname -> m (Either Error Customer)
rollLotteryWinner baseUrl token name = do
    res <- liftAff $ request $
        (defaultRequest baseUrl (Just token) { endpoint: RollWinner name, method: Post })
    case res of
        Left e ->
            pure $ Left $ explain "getting lottos" e
        Right v -> case Codec.decode (CAR.object "response" { who: Customer.codec }) v.body of
            Left er ->
                pure $ Left $ explain "parsing lotto response" er
            Right { who } ->
                pure $ Right who

-- TODO: tickets
getLottery :: forall m. MonadAff m => BaseURL -> Token -> Lottoname -> m (Either Error Lotto)
getLottery baseUrl token name = do
    res <- liftAff $ request $
        (defaultRequest baseUrl (Just token) { endpoint: GetLotto name, method: Get })
    case res of
        Left e ->
            pure $ Left $ explain "getting lottery" e
        Right v -> case Codec.decode (CAR.object "response" { lotto: Lotto.codec }) v.body of
            Left er ->
                pure $ Left $ explain "parsing lotto response" er
            Right { lotto } ->
                pure $ Right lotto

buyTicket :: forall m. MonadAff m => BaseURL -> Token -> Lottoname -> m (Either Error Unit)
buyTicket = ?a

tokenKey = "token" :: String

readToken :: Effect (Maybe Token)
readToken = do
  str <- getItem tokenKey =<< localStorage =<< window
  pure $ map Token (str >>= UUID.parseUUID)

writeToken :: Token -> Effect Unit
writeToken (Token str) =
  setItem tokenKey (UUID.toString str) =<< localStorage =<< window

removeToken :: Effect Unit
removeToken =
  removeItem tokenKey =<< localStorage =<< window
