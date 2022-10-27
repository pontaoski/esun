module Data.Profile where

import Data.Codec.Argonaut (JsonCodec)
import Data.Codec.Argonaut.Record as CAR
import Data.Customer (Customer)
import Data.Customer as Customer
import Data.Token (Token)
import Data.UUID (UUID)
import Data.UUIDCodec as UUIDCodec
import Data.Username (Username)
import Data.Username as Username

type ProfileRep row =
    ( username :: Username
    , id :: UUID
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
        }

profileWithCustomerCodec :: JsonCodec ProfileWithCustomer
profileWithCustomerCodec =
    CAR.object "Profile"
        { username: Username.codec
        , id: UUIDCodec.codec
        , customer: Customer.codec
        }
