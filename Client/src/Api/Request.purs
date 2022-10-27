module Api.Request where

import Prelude

import Affjax.RequestBody as RB
import Affjax.RequestHeader (RequestHeader(..))
import Affjax.ResponseFormat as RF
import Affjax.Web (Request, printError, request)
import Api.Endpoint (Endpoint(..), endpointCodec)
import Data.Argonaut.Core (Json)
import Data.Codec as Codec
import Data.Codec.Argonaut (JsonDecodeError, printJsonDecodeError)
import Data.Either (Either(..))
import Data.HTTP.Method (Method(..))
import Data.Maybe (Maybe(..))
import Data.Profile (MyProfile, Profile)
import Data.Profile as Profile
import Data.Token (Token(..))
import Data.Tuple (Tuple(..))
import Data.UUID as UUID
import Effect.Aff.Class (class MonadAff, liftAff)
import Routing.Duplex (print)

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
      Just (Token t) -> [ RequestHeader "Authorization" $ "Token " <> UUID.toString t ]
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

decodeProfile :: Json -> Either JsonDecodeError Profile
decodeProfile user = do
    Codec.decode Profile.profileCodec user

me :: forall m. MonadAff m => BaseURL -> Token -> m (Either String MyProfile)
me baseUrl token = do
    res <- liftAff $ request $ defaultRequest baseUrl Nothing { endpoint: Me, method: Get }
    case res of
        Left e -> pure $ Left $ printError e
        Right v -> do
            case decodeProfile v.body of
                Left er -> pure $ Left $ printJsonDecodeError er
                Right p ->
                    pure $ Right $ {username: p.username, id: p.id, token: token}
