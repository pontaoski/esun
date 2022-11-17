module Test.JSON where

import Prelude
import Test.Spec (Spec, describe, it)

import Data.Argonaut.Parser as DAR
import Data.AuditLogEntry as ALE
import Data.Bifunctor (lmap)
import Data.Codec as Codec
import Data.Codec.Argonaut (printJsonDecodeError)
import Data.Either (Either(..))
import Test.Spec.Assertions (fail)

exampleData :: String
exampleData =
    """
    {
        "involved": [
            {
                "customer": {
                    "id": "16D6AD3A-E589-475A-959D-6DA40E4B606D",
                    "user": {
                        "created": true,
                        "username": "OnceDoceTrece",
                        "admin": false,
                        "teller": false,
                        "id": "900B9435-583E-41BD-8E92-7FE0A182651B",
                        "role": "user"
                    },
                    "ironBalance": 5,
                    "diamondBalance": 5
                },
                "role": "initiator",
                "id": "B56FD4D3-7C17-4F56-B805-5BAB61093A78",
                "entry": {
                    "id": "67E9B2E9-F237-4FCE-81E0-30F4333684AC"
                }
            }
        ],
        "kind": "createDepositCode",
        "createdAt": "2022-11-17T06:16:49Z",
        "data": {
            "createDepositCode": {
                "diamonds": 5,
                "code": "fc1-fuc-9h4g",
                "iron": 5
            }
        },
        "recipient": null,
        "initiator": {
            "id": "16D6AD3A-E589-475A-959D-6DA40E4B606D",
            "user": {
                "created": true,
                "username": "OnceDoceTrece",
                "admin": false,
                "teller": false,
                "id": "900B9435-583E-41BD-8E92-7FE0A182651B",
                "role": "user"
            },
            "ironBalance": 5,
            "diamondBalance": 5
        },
        "id": "67E9B2E9-F237-4FCE-81E0-30F4333684AC"
    }
    """

json :: Spec Unit
json =
    describe "JSON Handling" do
        it "parses audit log entry" do
            let
                woo = do
                    js <- DAR.jsonParser exampleData
                    res <- lmap printJsonDecodeError $ Codec.decode ALE.codec js
                    pure res
            case woo of
                Left error -> do
                    fail error
                Right _ ->
                    pure unit

