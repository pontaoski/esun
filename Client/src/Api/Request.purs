module Api.Request where

import Prelude

import Affjax.RequestBody as RB
import Affjax.RequestHeader (RequestHeader(..))
import Affjax.ResponseFormat as RF
import Affjax.Web (Request, printError, request)
import Api.Endpoint (Endpoint(..), Pagination, endpointCodec)
import Data.Argonaut.Core (Json)
import Data.AuditLogEntry (AuditLogEntry)
import Data.AuditLogEntry as AuditLogEntry
import Data.Codec as Codec
import Data.Codec.Argonaut (JsonCodec, JsonDecodeError, printJsonDecodeError)
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Record as CAR
import Data.Either (Either(..))
import Data.Error (Error, explain)
import Data.HTTP.Method (Method(..))
import Data.Maybe (Maybe(..))
import Data.Page (Page)
import Data.Page as Page
import Data.Profile (MyProfile, Profile)
import Data.Profile as Profile
import Data.Token (Token(..))
import Data.Tuple (Tuple(..))
import Data.UUID as UUID
import Data.Username (Username(..))
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
                    pure $ Right $ {username: p.user.username, id: p.user.id, customer: p.user.customer, token: token}

account :: forall m. MonadAff m => BaseURL -> Username -> m (Either Error Profile)
account baseUrl username = do
    res <- liftAff $ request $ defaultRequest baseUrl Nothing { endpoint: Account username, method: Get }
    case res of
        Left e -> pure $ Left $ explain "getting account" e
        Right v -> do
            case decodeProfileResponse Profile.profileCodec v.body of
                Left er -> pure $ Left $ explain "parsing audit log response" er
                Right p ->
                    pure $ Right $ {username: p.user.username, id: p.user.id}

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
