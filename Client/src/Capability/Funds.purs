module Capability.Funds where

import PreludeP

import Control.Monad.Cont.Trans (lift)
import Data.Username (Username)
import Halogen (HalogenM)

class Monad m <= Funds m where
    transferMoney :: { iron :: Int, diamonds :: Int, to :: Username } -> m (Either Error Unit)
    adjustBalance :: { iron :: Int, diamonds :: Int, target :: Username } -> m (Either Error Unit)

instance fundsHalogenM :: Funds m => Funds (HalogenM st act slots msg m) where
    transferMoney = lift <<< transferMoney
    adjustBalance = lift <<< adjustBalance
