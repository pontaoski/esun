module Capability.Shop where

import Prelude

import Api.Endpoint (Pagination)
import Data.Either (Either)
import Data.Error (Error)
import Data.Maybe (Maybe)
import Data.Page (Page)
import Data.Shop (Shop, ShopListingData, ShopListing)
import Data.UUID (UUID)
import Data.Username (Username)
import Halogen (HalogenM, lift)

class Monad m <= Shops m where
    getShop :: String -> m (Either Error Shop)
    getShopItems :: Pagination -> String -> m (Either Error (Page ShopListing))
    createShop :: String -> String -> String -> m (Either Error Shop)
    getShopListing :: String -> UUID -> m (Either Error ShopListing)
    createShopListing :: String -> ShopListingData -> Maybe Int -> Maybe Int -> Maybe Boolean -> Int -> Int -> m (Either Error ShopListing)
    getShopsOwnedBy :: Pagination -> Username -> m (Either Error (Page Shop))

instance shopsHalogenM :: Shops m => Shops (HalogenM st act slots msg m) where
    getShop = lift <<< getShop
    getShopItems pagination name = lift $ getShopItems pagination name
    createShop title description slug = lift $ createShop title description slug
    getShopListing shop id = lift $ getShopListing shop id
    createShopListing shop dat stock quantity compacted diamond iron = lift $ createShopListing shop dat stock quantity compacted diamond iron
    getShopsOwnedBy pagination owner = lift $ getShopsOwnedBy pagination owner
