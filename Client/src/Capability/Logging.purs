module Capability.Logging where

import Prelude

import Control.Monad.Trans.Class (lift)
import Data.Foldable (fold)
import Halogen (HalogenM)

data LogLevel = Dev | Prod

derive instance eqLogLevel :: Eq LogLevel
derive instance ordLogLevel :: Ord LogLevel

data LogReason = Debug | Info | Warn | Error

derive instance eqLogReason :: Eq LogReason
derive instance ordLogReason :: Ord LogReason

newtype Log = Log
    { reason :: LogReason
    , message :: String
    }

derive instance eqLog :: Eq Log

message :: Log -> String
message (Log { message: m }) = m

reason :: Log -> LogReason
reason (Log { reason: r }) = r

mkLog :: LogReason -> String -> Log
mkLog logReason inputMessage =
    let
        texty = case logReason of
            Debug -> "Debug"
            Info -> "Info"
            Warn -> "Warn"
            Error -> "Error"
        out =
            Log { message: fold [ texty, " ", inputMessage ], reason: logReason }
    in
    out

class Monad m <= Logging m where
    log :: Log -> m Unit

instance navigateHalogenM :: Logging m => Logging (HalogenM st act slots msg m) where
    log = lift <<< log

log_ :: forall m. Logging m => LogReason -> String -> m Unit
log_ why text = log $ mkLog why text

logDebug :: forall m. Logging m => String -> m Unit
logDebug = log_ Debug

logInfo :: forall m. Logging m => String -> m Unit
logInfo = log_ Info

logWarn :: forall m. Logging m => String -> m Unit
logWarn = log_ Warn

logError :: forall m. Logging m => String -> m Unit
logError = log_ Error

