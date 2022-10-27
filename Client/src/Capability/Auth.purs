module Capability.Auth where

import Prelude

import Data.Token (Token)
import Control.Monad.Trans.Class (lift)
import Data.Maybe (Maybe)
import Data.Profile (MyProfile)
import Halogen (HalogenM)

class Monad m <= Auth m where
    loginUser :: Token -> m (Maybe MyProfile)
    logoutUser :: m Unit

instance navigateHalogenM :: Auth m => Auth (HalogenM st act slots msg m) where
    loginUser = lift <<< loginUser
    logoutUser = lift logoutUser