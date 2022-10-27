module Page.Home where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH

data Action
  = Initialize

type State =
    { idk :: Int
    }

component
    :: forall q o m
    . MonadAff m
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
        { idk: 5
        }

    render :: forall slots. State -> H.ComponentHTML Action slots m
    render _ =
        HH.div_
            [ HH.p_ [ HH.text "home page"] ]

    handleAction :: forall slots. Action -> H.HalogenM State Action slots o m Unit
    handleAction = case _ of
        Initialize ->
            H.modify_ _ { idk = 3 }