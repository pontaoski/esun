module Page.CreateDepositCode where

import Prelude

import Component.HTML.Utils (css)
import Data.Int (toNumber)
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
        contents = HH.div [ css "flex", css "flex-col", css "items-center" ]
            [ HH.div [ css "flex", css "flex-col", css "space-y-4" ]
                [ HH.div_
                    [ HH.label [ HP.for "ironAmount" ] [ HH.text "Iron amount:" ]
                    , HH.input [ HP.id "ironAmount", HP.type_ HP.InputNumber, HP.min (toNumber 0) ]
                    ]
                , HH.div_ 
                    [ HH.label [ HP.for "diamondAmount" ] [ HH.text "Diamond amount:" ]
                    , HH.input [ HP.id "diamondAmount", HP.type_ HP.InputNumber, HP.min (toNumber 0) ]
                    ]
                , HH.input [ HP.type_ HP.InputSubmit, HP.value "Create Deposit Code" ]
                ]
            , HH.p [ css "max-w-lg" ]
                [ HH.text
                    """
                    You can move some funds from your account into a deposit code, which will allow
                    whoever has the code to receive the funds into their own account.
                    If you want to give funds to a specific player directly, you should do a direct
                    transfer.
                    """
                ]
            ]

    handleAction = case _ of
        Initialize new -> do
            H.modify_ _ { myUser = new }
