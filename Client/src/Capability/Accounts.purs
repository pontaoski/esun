module Capability.Accounts where

import Prelude

import Control.Monad.Cont.Trans (lift)
import Data.Either (Either)
import Data.Error (Error)
import Data.Profile (Profile)
import Data.Username (Username)
import Halogen (HalogenM)

class Monad m <= Accounts m where
    getUser :: Username -> m (Either Error Profile)

instance accountsHalogenM :: Accounts m => Accounts (HalogenM st act slots msg m) where
    getUser = lift <<< getUser
