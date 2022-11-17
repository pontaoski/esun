module Page.CreateDepositCode where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Profile (MyProfile)
import Halogen (ClassName(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

type State =
    { myUser :: MyProfile
    }

data Action
    = Initialize MyProfile

component
    :: forall q o m
    . H.Component q MyProfile o m
component =
    H.mkComponent
        { initialState
        , render
        , eval: H.mkEval $ H.defaultEval
            { handleAction = handleAction
            , initialize = Nothing
            , receive = \x -> Just $ Initialize x
            }
        }

    where
    initialState myUser =
        { myUser }

    render _ =
        HH.div [ HP.classes [ ClassName "folder" ] ]
            [ HH.div [ HP.class_ $ ClassName "folder-tab "] [ HH.text title ]
            , HH.div [ HP.class_ $ ClassName "folder-body" ] [ contents ]
            ]
        where
        title = "Create Deposit Code"
        contents = HH.div_ []

    handleAction = case _ of
        Initialize new -> do
            H.modify_ _ { myUser = new }
