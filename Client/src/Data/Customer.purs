module Data.Customer where

import Data.Codec.Argonaut (JsonCodec)
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Record as CAR
import Data.UUID (UUID)
import Data.UUIDCodec as UUIDCodec

type Customer =
    { id :: UUID
    , ironBalance :: Int
    , diamondBalance :: Int
    }

codec :: JsonCodec Customer
codec =
    CAR.object "Customer"
        { id: UUIDCodec.codec
        , ironBalance: CA.int
        , diamondBalance: CA.int
        }
