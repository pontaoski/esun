module Data.Token where

import Prelude

import Data.UUID (UUID)

newtype Token = Token UUID

derive instance eqToken :: Eq Token
derive instance ordToken :: Ord Token

instance showToken :: Show Token where
    show (Token _) = "Token (hidden)"
