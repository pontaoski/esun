module Data.Page where

import Data.Codec.Argonaut (JsonCodec)
import Data.Codec.Argonaut.Common as CAC
import Data.Codec.Argonaut.Record as CAR
import Data.List (List)

type Page a =
    { items :: List a
    , metadata ::
        { page :: Int
        , per :: Int
        , total :: Int
        }
    }

codec :: forall a. JsonCodec a -> JsonCodec (Page a)
codec itemsCodec =
    CAR.object "page"
        { items: CAC.list itemsCodec
        , metadata: CAR.object "page metadata"
            { page: CAC.int
            , per: CAC.int
            , total: CAC.int
            }
        }
