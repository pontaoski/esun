module Capability.DepositCode where

import Prelude

import Control.Monad.Trans.Class (lift)
import Data.Error (Error)
import Data.Either (Either)
import Halogen (HalogenM)

class Monad m <= DepositCode m where
    createDepositCode :: { iron :: Int, diamonds :: Int } -> m (Either Error String)

instance depositCodeHalogenM :: DepositCode m => DepositCode (HalogenM st act slots msg m) where
    createDepositCode = lift <<< createDepositCode
