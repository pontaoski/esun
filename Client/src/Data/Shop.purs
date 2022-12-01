module Data.Shop where

import Prelude

import Data.Argonaut.Core (Json, fromObject, toObject)
import Data.Codec (decode)
import Data.Codec as C
import Data.Codec.Argonaut (JsonCodec, JsonDecodeError(..))
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Common as CAC
import Data.Codec.Argonaut.Record as CAR
import Data.Either (Either(..))
import Data.List (List)
import Data.Maybe (Maybe(..))
import Data.UUID (UUID)
import Data.UUIDCodec as UUIDCodec
import Foreign.Object as Object

type Shop =
    { id :: UUID
    , title :: String
    , description :: String
    , slug :: String
    }

shopCodec :: JsonCodec Shop
shopCodec =
    CAR.object "Shop"
        { id: UUIDCodec.codec
        , title: CA.string
        , description: CA.string
        , slug: CA.string
        }

type ShopListing =
    { id :: UUID
    , createdBy :: UUID
    , data :: ShopListingData
    , stock :: Maybe Int
    , quantity :: Maybe Int
    , compacted :: Maybe Boolean
    , diamondPrice :: Int
    , ironPrice :: Int
    }

shopListCodec :: JsonCodec ShopListing
shopListCodec =
    C.codec toItem fromItem
    where
    toItem :: Json -> Either JsonDecodeError ShopListing
    toItem json = do
        res <- decode baselineCodec json
        let
            { id, createdBy, stock, quantity, compacted, diamondPrice, ironPrice } =
                res
            ken = do
                obj <- toObject json
                pure (Object.lookup "item" obj /= Nothing)
        case ken of
            Just x | x -> do
                obj <- decode itemCodec json
                pure $ { id, createdBy, stock, quantity, compacted, diamondPrice, ironPrice, data: Item obj }
            Just _ -> do
                obj <- decode customCodec json
                pure $ { id, createdBy, stock, quantity, compacted, diamondPrice, ironPrice, data: Other obj }
            Nothing ->
                Left MissingValue

    baselineCodec :: JsonCodec { id :: UUID, createdBy :: UUID, stock :: Maybe Int, quantity :: Maybe Int, compacted :: Maybe Boolean, diamondPrice :: Int, ironPrice :: Int }
    baselineCodec =
        CAR.object "shop listing"
            { id: UUIDCodec.codec
            , createdBy: UUIDCodec.codec
            , stock: CAR.optional CA.int
            , quantity: CAR.optional CA.int
            , compacted: CAR.optional CA.boolean
            , diamondPrice: CA.int
            , ironPrice: CA.int
            }

    itemCodec :: JsonCodec { item :: String, enchants :: List Enchant }
    itemCodec =
        CAR.object "item fields"
            { item: CA.string
            , enchants: CAC.list enchantCodec
            }

    customCodec :: JsonCodec { title :: String, description :: String }
    customCodec =
        CAR.object "custom fields"
            { title: CA.string
            , description: CA.string
            }

    fromItem :: ShopListing -> Json
    fromItem _ =
        Object.empty
        # fromObject

type Enchant =
    { name :: String
    , level :: Int
    }

enchantCodec :: JsonCodec Enchant
enchantCodec =
    CAR.object "enchant information"
        { name: CA.string
        , level: CA.int
        }

data ShopListingData
    = Item { item :: String, enchants :: List Enchant }
    | Other { title :: String, description :: String }
