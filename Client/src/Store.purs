module Store where

import Prelude

import Api.Request (BaseURL)
import Capability.Logging (LogLevel)
import Data.Maybe (Maybe(..))
import Data.Profile (MyProfile)

type Store =
    { logLevel :: LogLevel
    , baseUrl :: BaseURL
    , currentUser :: Maybe MyProfile
    }

data Action
  = LoginUser MyProfile
  | LogoutUser

reduce :: Store -> Action -> Store
reduce store = case _ of
    LoginUser profile ->
        store { currentUser = Just profile }

    LogoutUser ->
        store { currentUser = Nothing }
