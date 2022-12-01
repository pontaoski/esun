module Data.Error where

import Prelude

import Affjax (printError)
import Affjax as Affjax
import Data.Codec.Argonaut (JsonDecodeError, printJsonDecodeError)

data Error
    = AuthRequired
    | NotImplemented String
    | Affjax Affjax.Error
    | JsonDecodeError JsonDecodeError
    | Context String Error
    | Custom String

class Errorable m where
    toError :: m -> Error

explain :: forall m. Errorable m => String -> m -> Error
explain context error =
    Context context (toError error)

toString :: forall m. Errorable m => m -> String
toString error =
    case toError error of
        AuthRequired -> "authenticaiton is required"
        NotImplemented x -> x <> " is not implemented"
        Affjax x -> printError x
        JsonDecodeError x -> printJsonDecodeError x
        Context ctx x -> "while " <> ctx <> ": " <> (toString x)
        Custom str -> str

instance errorableError :: Errorable Error where
    toError self =
        self

instance errorableAffjax :: Errorable Affjax.Error where
    toError self =
        Affjax self

instance errorableJDE :: Errorable JsonDecodeError where
    toError self =
        JsonDecodeError self
