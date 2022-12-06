module Page.Home
  ( component
  )
  where

import Prelude

import Capability.Auth (class Auth, getCurrentUser)
import Component.HTML.Utils (css, safeHref)
import Data.Maybe (Maybe(..))
import Data.Profile (MyProfile)
import Data.Route (AuthRoute(..), Route(..))
import Data.String (Pattern(..), Replacement(..))
import Data.String as String
import Data.UUID as UUID
import Data.Username as Username
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

type State =
    {
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
        , eval: H.mkEval H.defaultEval
        }
    where
    initialState _ =
        {
        }

    render :: forall action slots. State -> H.ComponentHTML action slots m
    render state =
        HH.div [ css ["folder"] ]
            [ HH.div [ css ["folder-tab"] ] [ HH.text title ]
            , HH.div [ css ["folder-body"] ] [ contents ]
            ]
        where
        title = "Welcome to Esun"
        contents = HH.p_ [ HH.text "home page"]
