module Capability.Lotto where

import Prelude

import Api.Request (CreateLottoRequest)
import Control.Monad.Trans.Class (lift)
import Data.Customer (Customer)
import Data.Either (Either)
import Data.Error (Error)
import Data.Lotto (Lottoname, Lotto)
import Data.Page (Page)
import Halogen (HalogenM)

class Monad m <= Lottos m where
    createLotto :: CreateLottoRequest -> m (Either Error Lotto)
    myLottos :: m (Either Error (Page Lotto))
    lottoInfo :: Lottoname -> m (Either Error Lotto)
    buyTicket :: Lottoname -> m (Either Error Unit)
    rollWinner :: Lottoname -> m (Either Error Customer)

instance lottoHalogenM :: Lottos m => Lottos (HalogenM st act slots msg m) where
    createLotto = lift <<< createLotto
    myLottos = lift myLottos
    lottoInfo = lift <<< lottoInfo
    buyTicket = lift <<< buyTicket
    rollWinner = lift <<< rollWinner
