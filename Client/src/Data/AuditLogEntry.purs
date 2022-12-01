module Data.AuditLogEntry
  ( AuditLogCustomer
  , AuditLogEntry(..)
  , codec
  , swiftToArgonaut
  )
  where

import Prelude

import Data.Argonaut.Core (toObject)
import Data.Argonaut.Core as J
import Data.Array as Array
import Data.Codec as C
import Data.Codec.Argonaut (JsonDecodeError(..), JsonCodec, (<~<))
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
import Data.Username (Username(..))
import Data.Username as Username
import Foreign.Object as Object
import Partial.Unsafe (unsafeCrashWith)

type AuditLogCustomer =
    { id :: UUID
    , user ::
        { username :: Username
        }
    }

data AuditLogEntry
    = MoneyTransfer { iron :: Int, diamonds :: Int, from :: AuditLogCustomer, to :: AuditLogCustomer }
    | BalanceAdjustment { iron :: Int, diamonds :: Int, target :: AuditLogCustomer, teller :: AuditLogCustomer }
    | CreateDepositCode { code :: String, iron :: Int, diamonds :: Int, creator :: AuditLogCustomer }
    | CreateWithdrawalCode { code :: String, iron :: Int, diamonds :: Int, creator :: AuditLogCustomer }
    | UseDepositCode { code :: String, iron :: Int, diamonds :: Int, user :: AuditLogCustomer }
    | UseWithdrawalCode { code :: String, iron :: Int, diamonds :: Int, user :: AuditLogCustomer }

data JSONAuditLogEntry
    = JMoneyTransfer { iron :: Int, diamonds :: Int }
    | JBalanceAdjustment { iron :: Int, diamonds :: Int }
    | JCreateDepositCode { code :: String, iron :: Int, diamonds :: Int }
    | JCreateWithdrawalCode { code :: String, iron :: Int, diamonds :: Int }
    | JUseDepositCode { code :: String, iron :: Int, diamonds :: Int }
    | JUseWithdrawalCode { code :: String, iron :: Int, diamonds :: Int }

data JSONAuditLogTag
    = JTMoneyTransfer
    | JTBalanceAdjustment
    | JTCreateDepositCode
    | JTCreateWithdrawalCode
    | JTUseDepositCode
    | JTUseWithdrawalCode

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
                JTCreateWithdrawalCode -> "createWithdrawalCode"
                JTUseDepositCode -> "useDepositCode"
                JTUseWithdrawalCode -> "useWithdrawalCode"
        parseTag =
            case _ of
                "moneyTransfer" -> Just JTMoneyTransfer
                "balanceAdjustment" -> Just JTBalanceAdjustment
                "createDepositCode" -> Just JTCreateDepositCode
                "createWithdrawalCode" -> Just JTCreateWithdrawalCode
                "useDepositCode" -> Just JTUseDepositCode
                "useWithdrawalCode" -> Just JTUseWithdrawalCode
                _ -> Nothing
        f =
            case _ of
                JTMoneyTransfer -> Right $ Codec.decode codecMoneyTransfer
                JTBalanceAdjustment -> Right $ Codec.decode codecBalanceAdjustment
                JTCreateDepositCode -> Right $ Codec.decode codecCreateDepositCode
                JTCreateWithdrawalCode -> Right $ Codec.decode codecCreateWithdrawalCode
                JTUseDepositCode -> Right $ Codec.decode codecUseDepositCode
                JTUseWithdrawalCode -> Right $ Codec.decode codecUseWithdrawalCode
        g =
            case _ of
                JMoneyTransfer x -> Tuple JTMoneyTransfer $ Just $ Codec.encode codecMoneyTransfer x
                JBalanceAdjustment x -> Tuple JTBalanceAdjustment $ Just $ Codec.encode codecBalanceAdjustment x
                JCreateDepositCode x -> Tuple JTCreateDepositCode $ Just $ Codec.encode codecCreateDepositCode x
                JCreateWithdrawalCode x -> Tuple JTCreateWithdrawalCode $ Just $ Codec.encode codecCreateWithdrawalCode x
                JUseDepositCode x -> Tuple JTUseDepositCode $ Just $ Codec.encode codecUseDepositCode x
                JUseWithdrawalCode x -> Tuple JTUseWithdrawalCode $ Just $ Codec.encode codecUseWithdrawalCode x

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

        codecCreateWithdrawalCode =
            CAR.object "CreateDepositCode"
                { iron: CA.int
                , diamonds: CA.int
                , code : CA.string
                }
            # map JCreateWithdrawalCode

        codecUseDepositCode =
            CAR.object "CreateDepositCode"
                { iron: CA.int
                , diamonds: CA.int
                , code : CA.string
                }
            # map JUseDepositCode

        codecUseWithdrawalCode =
            CAR.object "CreateDepositCode"
                { iron: CA.int
                , diamonds: CA.int
                , code : CA.string
                }
            # map JUseWithdrawalCode

codec :: JsonCodec AuditLogEntry
codec =
    CA.codec dec enc
    where
        dec :: J.Json -> Either JsonDecodeError AuditLogEntry
        dec js = do
            rawd <- CA.decode raw js
            let
                getRole :: String -> Either JsonDecodeError AuditLogCustomer
                getRole role =
                    case List.find (\x -> x.role == role) rawd.involved of
                        Just x -> Right x.customer
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
                JCreateWithdrawalCode { code, iron, diamonds } -> do
                    user <- getRole "initiator"
                    Right $ CreateWithdrawalCode { code, iron, diamonds, creator: user }
                JUseDepositCode { code, iron, diamonds } -> do
                    user <- getRole "initiator"
                    Right $ UseDepositCode { code, iron, diamonds, user }
                JUseWithdrawalCode { code, iron, diamonds } -> do
                    user <- getRole "initiator"
                    Right $ UseWithdrawalCode { code, iron, diamonds, user }

        enc :: AuditLogEntry -> J.Json
        enc _ =
            J.jsonNull


        raw = CAR.object "raw json"
            { data: jALE
            , involved: CAC.list $ CAR.object "involvement"
                { customer: customerCodec
                , role: CA.string
                }
            }

        customerCodec :: JsonCodec AuditLogCustomer
        customerCodec =
            CAR.object "customer"
                { id: UUIDCodec.codec
                , user: CAR.object "customer user"
                    { username: Username.codec
                    }
                }
