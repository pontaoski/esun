module Data.Lotto
  ( Lotto
  , Lottoname
  , codec
  , fromString
  , lottonameCodec
  , parse
  , toString
  )
  where

import Prelude

import Data.Codec.Argonaut (JsonCodec)
import Data.Codec.Argonaut as CA
import Data.Profunctor (dimap)
import Data.Maybe (Maybe(..))
import Data.Codec.Argonaut.Common as CAC
import Data.Codec.Argonaut.Record as CAR

newtype Lottoname = Lottoname String

derive instance eqLottoname :: Eq Lottoname
derive instance ordLottoname :: Ord Lottoname
derive newtype instance showLottoname :: Show Lottoname

lottonameCodec :: JsonCodec Lottoname
lottonameCodec = (dimap toString) Lottoname CA.string

parse :: String -> Maybe Lottoname
parse "" = Nothing
parse str = Just (Lottoname str)

fromString :: String -> Lottoname
fromString str = Lottoname str

toString :: Lottoname -> String
toString (Lottoname str) = str

type Lotto =
    { ticketPrice :: Int
    , maxTicketsPerCustomer :: Int
    , houseCut :: Number
    , title :: String
    , description :: String
    , slug :: String
    }

codec :: JsonCodec Lotto
codec =
    CAR.object "lotto"
        { ticketPrice: CAC.int
        , maxTicketsPerCustomer: CAC.int
        , houseCut: CAC.number
        , title: CAC.string
        , description: CAC.string
        , slug: CAC.string
        }
