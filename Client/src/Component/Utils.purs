module Component.Utils where

import Prelude

import Data.Profile (MyProfile)
import Halogen as H

type OpaqueSlot slot = forall query. H.Slot query Void slot
