module Data.Profile where

import Prelude

import Data.Codec.Argonaut (JsonCodec)
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Record as CAR
import Data.Codec.Argonaut.Sum as CAS
import Data.Customer (Customer)
import Data.Customer as Customer
import Data.Maybe (Maybe(..))
import Data.Token (Token)
import Data.Tuple (Tuple(..))
import Data.UUID (UUID)
import Data.UUIDCodec as UUIDCodec
import Data.Username (Username)
import Data.Username as Username

data SiteRole
    = Admin
    | Teller
    | User

derive instance siteRoleEq :: Eq SiteRole
instance siteRoleOrd :: Ord SiteRole where
    compare lhs rhs = case Tuple lhs rhs of
        Tuple lhs' rhs' | lhs' == rhs' -> EQ
        Tuple Admin _ -> GT
        Tuple _ Admin -> LT
        Tuple Teller _ -> GT
        Tuple _ Teller -> LT
        Tuple _ _ -> EQ

type ProfileRep row =
    ( username :: Username
    , id :: UUID
    , created :: Boolean
    , role :: SiteRole
    | row
    )

type ProfileWithCustomerRep row =
    ( customer :: Customer
    | ProfileRep row
    )

type Profile = { | ProfileRep () }
type ProfileWithCustomer = { | ProfileWithCustomerRep () }
type MyProfile = { | ProfileWithCustomerRep ( token :: Token ) }

profileCodec :: JsonCodec Profile
profileCodec =
    CAR.object "Profile"
        { username: Username.codec
        , id: UUIDCodec.codec
        , created: CA.boolean
        , role: siteRoleCodec
        }

profileWithCustomerCodec :: JsonCodec ProfileWithCustomer
profileWithCustomerCodec =
    CAR.object "Profile"
        { username: Username.codec
        , id: UUIDCodec.codec
        , customer: Customer.codec
        , created: CA.boolean
        , role: siteRoleCodec
        }

siteRoleCodec :: JsonCodec SiteRole
siteRoleCodec =
    CAS.enumSum toStr fromStr
    where
        toStr = case _ of
            Admin -> "admin"
            Teller -> "teller"
            User -> "user"
        fromStr = case _ of
            "admin" -> Just Admin
            "teller" -> Just Teller
            "user" -> Just User
            _ -> Nothing