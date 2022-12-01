module Component.Header where

import Prelude

import Capability.Auth (class Auth, getCurrentUser)
import Data.Maybe (Maybe(..))
import Data.Profile (MyProfile)
import Data.Username as Username
import Effect.Aff.Class (class MonadAff)
import Halogen (ClassName(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

data Action
  = Initialize

type State =
    { profile :: Maybe MyProfile
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
        { profile: Nothing
        }
    handleAction = case _ of
        Initialize -> do
            user <- getCurrentUser
            H.modify_ _ { profile = user }
    render state =
        HH.div [ HP.classes [ ClassName "p-2", ClassName "border-b", ClassName "flex", ClassName "justify-between" ] ] [
            HH.div_
                [ HH.text "Esun "
                , HH.span [ HP.classes [ ClassName "text-sm" ] ]
                    [ HH.text "by "
                    , HH.span [ HP.classes [ ClassName "font-bold", ClassName "text-[#649832]" ] ]
                        [ HH.text "Solitude" ]
                    , HH.text " Corporation"
                    ]
                ],
            case state.profile of
                Just x ->
                    HH.div [ HP.classes [] ] [ HH.text $ Username.toString x.username ]
                Nothing ->
                    HH.div_ [ HH.text "Log In" ]
        ]