module Capability.DepositCode where

import Prelude

import Control.Monad.Trans.Class (lift)
import Data.Error (Error)
import Data.Either (Either)
import Halogen (HalogenM)

class Monad m <= DepositCode m where
    createDepositCode :: { iron :: Int, diamonds :: Int } -> m (Either Error String)
    useDepositCode :: String -> m (Either Error { iron :: Int, diamonds :: Int })
    createWithdrawalCode :: { password :: String, iron :: Int, diamonds :: Int } -> m (Either Error String)
    useWithdrawalCode :: String -> m (Either Error { password :: String, iron :: Int, diamonds :: Int })

instance depositCodeHalogenM :: DepositCode m => DepositCode (HalogenM st act slots msg m) where
    createDepositCode = lift <<< createDepositCode
    useDepositCode = lift <<< useDepositCode
    createWithdrawalCode = lift <<< createWithdrawalCode
    useWithdrawalCode = lift <<< useWithdrawalCode
