module Data.Shopname where

import Prelude

import Data.Codec.Argonaut (JsonCodec)
import Data.Codec.Argonaut as CA
import Data.Profunctor (dimap)
import Data.Maybe (Maybe(..))

newtype Shopname = Shopname String

derive instance eqShopname :: Eq Shopname
derive instance ordShopname :: Ord Shopname

codec :: JsonCodec Shopname
codec = dimap (\(Shopname user) -> user) Shopname CA.string

parse :: String -> Maybe Shopname
parse "" = Nothing
parse str = Just (Shopname str)

toString :: Shopname -> String
toString (Shopname str) = str
