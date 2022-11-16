module Data.AuditLogEntry (
    AuditLogEntry(..),
    codec
) where

import Data.Codec.Argonaut.Common (JsonCodec)
import Data.Codec.Argonaut.Common as CA
import Data.Codec.Argonaut.Record as CAR
import Data.Maybe (Maybe(..))
import Data.UUID (UUID)

data AuditLogEntry
    = MoneyTransfer { iron :: Int, diamonds :: Int, from :: UUID, to :: UUID }
    | BalanceAdjustment { iron :: Int, diamonds :: Int, target :: UUID, teller :: UUID }
    | CreateDepositCode { code :: Int, iron :: Int, diamonds :: Int }

codec :: JsonCodec AuditLogEntry
codec =
    CA.prismaticCodec "unimplemented audit log entry" dec enc raw
    where
        dec _ = Nothing
        enc _ = {}
        raw = CAR.object "raw json"
            { -- data: CA.int
            -- , involved: CAC.list $ CAR.object "involvement"
            --     { customer_id: UUIDCodec.codec
            --     , role: CA.string
            --     }
            }
