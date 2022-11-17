module Data.AuditLogEntry
  ( AuditLogEntry(..)
  , codec
  , swiftToArgonaut
  )
  where

import Prelude

import Data.Argonaut.Core (toObject)
import Data.Argonaut.Core as J
import Data.Array as Array
import Data.Codec as C
import Data.Codec.Argonaut (JsonDecodeError(..), (<~<))
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut as Codec
import Data.Codec.Argonaut.Common (JsonCodec)
import Data.Codec.Argonaut.Common as CAC
import Data.Codec.Argonaut.Record as CAR
import Data.Codec.Argonaut.Sum (taggedSum)
import Data.Either (Either(..))
import Data.List as List
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Data.UUID (UUID)
import Data.UUIDCodec as UUIDCodec
import Foreign.Object as Object
import Partial.Unsafe (unsafeCrashWith)

data AuditLogEntry
    = MoneyTransfer { iron :: Int, diamonds :: Int, from :: UUID, to :: UUID }
    | BalanceAdjustment { iron :: Int, diamonds :: Int, target :: UUID, teller :: UUID }
    | CreateDepositCode { code :: String, iron :: Int, diamonds :: Int, creator :: UUID }

data JSONAuditLogEntry
    = JMoneyTransfer { iron :: Int, diamonds :: Int }
    | JBalanceAdjustment { iron :: Int, diamonds :: Int }
    | JCreateDepositCode { code :: String, iron :: Int, diamonds :: Int }

data JSONAuditLogTag
    = JTMoneyTransfer
    | JTBalanceAdjustment
    | JTCreateDepositCode

swiftToArgonaut :: J.Json -> Either JsonDecodeError J.Json
swiftToArgonaut js = do
    let
        ken = do
            obj <- toObject js
            key <- Array.index (Object.keys obj) 0
            inner <- Object.lookup key obj
            pure $
                Object.empty
                # Object.insert "tag" (J.fromString key)
                # Object.insert "value" inner
                # J.fromObject
    case ken of
        Just x -> Right x
        Nothing -> Left MissingValue

argonautToSwift :: J.Json -> J.Json
argonautToSwift j =
    case inner j of
        Just x -> x
        Nothing -> unsafeCrashWith "argonaut gave me a bad :("
    where
    inner :: J.Json -> Maybe J.Json
    inner js = do
        obj <- toObject js
        key <- do
            prop <- Object.lookup "tag" obj
            str <- J.toString prop
            pure str
        dat <- Object.lookup "value" obj
        pure $
            Object.empty
            # Object.insert key dat
            # J.fromObject

converting :: forall a. JsonCodec a -> JsonCodec a
converting codec' = codec' <~< converter
    where
    converter = C.codec swiftToArgonaut argonautToSwift

jALE :: JsonCodec JSONAuditLogEntry
jALE =
    converting $ taggedSum name printTag parseTag f g
    where
        name = "audit log tag"
        printTag =
            case _ of
                JTMoneyTransfer -> "moneyTransfer"
                JTBalanceAdjustment -> "balanceAdjustment"
                JTCreateDepositCode -> "createDepositCode"
        parseTag =
            case _ of
                "moneyTransfer" -> Just JTMoneyTransfer
                "balanceAdjustment" -> Just JTBalanceAdjustment
                "createDepositCode" -> Just JTCreateDepositCode
                _ -> Nothing
        f =
            case _ of
                JTMoneyTransfer -> Right $ Codec.decode codecMoneyTransfer
                JTBalanceAdjustment -> Right $ Codec.decode codecBalanceAdjustment
                JTCreateDepositCode -> Right $ Codec.decode codecCreateDepositCode
        g =
            case _ of
                JMoneyTransfer x -> Tuple JTMoneyTransfer $ Just $ Codec.encode codecMoneyTransfer x
                JBalanceAdjustment x -> Tuple JTBalanceAdjustment $ Just $ Codec.encode codecBalanceAdjustment x
                JCreateDepositCode x -> Tuple JTCreateDepositCode $ Just $ Codec.encode codecCreateDepositCode x

        codecMoneyTransfer =
            CAR.object "MoneyTransfer"
                { iron: CA.int
                , diamonds: CA.int
                }
            # map JMoneyTransfer

        codecBalanceAdjustment =
            CAR.object "BalanceAdjustment"
                { iron: CA.int
                , diamonds: CA.int
                }
            # map JBalanceAdjustment

        codecCreateDepositCode =
            CAR.object "CreateDepositCode"
                { iron: CA.int
                , diamonds: CA.int
                , code : CA.string
                }
            # map JCreateDepositCode

codec :: JsonCodec AuditLogEntry
codec =
    CA.codec dec enc
    where
        dec :: J.Json -> Either JsonDecodeError AuditLogEntry
        dec js = do
            rawd <- CA.decode raw js
            let
                getRole :: String -> Either JsonDecodeError UUID
                getRole role =
                    case List.find (\x -> x.role == role) rawd.involved of
                        Just x -> Right x.customer.id
                        Nothing -> Left MissingValue
            case rawd.data of
                JMoneyTransfer { iron, diamonds } -> do
                    from <- getRole "initiator"
                    to <- getRole "recipient"
                    Right $ MoneyTransfer { from, to, iron, diamonds }
                JBalanceAdjustment { iron, diamonds } -> do
                    teller <- getRole "initiator"
                    target <- getRole "recipient"
                    Right $ BalanceAdjustment { iron, diamonds, target, teller }
                JCreateDepositCode { code, iron, diamonds } -> do
                    creator <- getRole "initiator"
                    Right $ CreateDepositCode { code, iron, diamonds, creator }

        enc :: AuditLogEntry -> J.Json
        enc _ =
            J.jsonNull


        raw = CAR.object "raw json"
            { data: jALE
            , involved: CAC.list $ CAR.object "involvement"
                { customer: CAR.object "customer" $
                    { id: UUIDCodec.codec
                    }
                , role: CA.string
                }
            }
