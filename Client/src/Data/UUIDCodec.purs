module Data.UUIDCodec where

import Data.Codec.Argonaut (JsonCodec)
import Data.Codec.Argonaut as CA
import Data.UUID (UUID)
import Data.UUID as UUID

codec :: JsonCodec UUID
codec = CA.prismaticCodec "UUID" UUID.parseUUID UUID.toString CA.string
