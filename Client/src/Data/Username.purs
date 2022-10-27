module Data.Username where

import Prelude

import Data.Codec.Argonaut (JsonCodec)
import Data.Codec.Argonaut as CA
import Data.Profunctor (dimap)
import Data.Maybe (Maybe(..))

newtype Username = Username String

derive instance eqUsername :: Eq Username
derive instance ordUsername :: Ord Username

codec :: JsonCodec Username
codec = (dimap toString) Username CA.string

parse :: String -> Maybe Username
parse "" = Nothing
parse str = Just (Username str)

toString :: Username -> String
toString (Username str) = str
