module Page.Home where

import Prelude

import Capability.Auth (class Auth, getCurrentUser)
import Data.Foldable (fold)
import Data.Maybe (Maybe(..))
import Data.Profile (MyProfile)
import Data.Username as Username
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH

data Action
  = Initialize

type State =
    { idk :: Maybe MyProfile
    }

component
    :: forall q o m
    . MonadAff m
    => Auth m
    => H.Component q Unit o m
component =
    H.mkComponent
        { initialState
        , render
        , eval: H.mkEval $ H.defaultEval
            { handleAction = handleAction
            , initialize = Just Initialize
            }
        }
    where
    initialState _ =
        { idk: Nothing
        }

    render :: forall slots. State -> H.ComponentHTML Action slots m
    render state =
        case state.idk of
            Just me ->
                HH.div_
                    [ HH.p_ [ HH.text $ fold ["home page ", Username.toString me.username] ] ]
            Nothing ->
                HH.div_
                    [ HH.p_ [ HH.text "home page"] ]

    handleAction :: forall slots. Action -> H.HalogenM State Action slots o m Unit
    handleAction = case _ of
        Initialize -> do
            user <- getCurrentUser
            H.modify_ _ { idk = user }