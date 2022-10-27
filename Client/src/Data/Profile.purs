module Data.Profile where

import Data.Codec.Argonaut (JsonCodec)
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Record as CAR
import Data.Token (Token)
import Data.UUID (UUID)
import Data.UUID as UUID
import Data.Username (Username)
import Data.Username as Username

type ProfileRep row =
    ( username :: Username
    , id :: UUID
    | row
    )

type Profile = { | ProfileRep () }
type MyProfile = { | ProfileRep ( token :: Token ) }

uuidCodec :: JsonCodec UUID
uuidCodec = CA.prismaticCodec "UUID" UUID.parseUUID UUID.toString CA.string

profileCodec :: JsonCodec Profile
profileCodec =
    CAR.object "Profile"
        { username: Username.codec
        , id: uuidCodec
        }
