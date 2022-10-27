module Api.Request where

import Prelude

import Affjax.RequestBody as RB
import Affjax.RequestHeader (RequestHeader(..))
import Affjax.ResponseFormat as RF
import Affjax.Web (Request, printError, request)
import Api.Endpoint (Endpoint(..), endpointCodec)
import Data.Argonaut.Core (Json)
import Data.Codec as Codec
import Data.Codec.Argonaut (JsonDecodeError, JsonCodec, printJsonDecodeError)
import Data.Codec.Argonaut.Record as CAR
import Data.Either (Either(..))
import Data.HTTP.Method (Method(..))
import Data.Maybe (Maybe(..))
import Data.Profile (MyProfile)
import Data.Profile as Profile
import Data.Token (Token(..))
import Data.Tuple (Tuple(..))
import Data.UUID as UUID
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

decodeProfileResponse :: forall a. JsonCodec a -> Json -> Either JsonDecodeError { user :: a }
decodeProfileResponse inner user = do
    Codec.decode (profileResponseCodec inner) user

me :: forall m. MonadAff m => BaseURL -> Token -> m (Either String MyProfile)
me baseUrl token = do
    res <- liftAff $ request $ defaultRequest baseUrl (Just token) { endpoint: Me, method: Get }
    case res of
        Left e -> pure $ Left $ printError e
        Right v -> do
            case decodeProfileResponse Profile.profileWithCustomerCodec v.body of
                Left er -> pure $ Left $ printJsonDecodeError er
                Right p ->
                    pure $ Right $ {username: p.user.username, id: p.user.id, customer: p.user.customer, token: token}


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
