module Page.UseDepositCode
  ( component
  )
  where

import Prelude

import Capability.DepositCode (class DepositCode, useDepositCode)
import Component.HTML.Utils (css)
import Data.Either (Either(..))
import Data.Error (Error)
import Data.Error as Error
import Data.Maybe (Maybe(..))
import Data.Profile (MyProfile)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

data Tripart a
    = Nichts
    | Pending
    | Result (Either Error a)

type State =
    { myUser :: MyProfile
    , code :: String
    , status :: Tripart { iron :: Int, diamonds :: Int }
    }

data Action
    = Initialize MyProfile
    | Code String
    | Submit

component
    :: forall q o m
    . DepositCode m
    => H.Component q MyProfile o m
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
    initialState :: MyProfile -> State
    initialState myUser =
        { myUser, code: "", status: Nichts }

    render :: forall slots. State -> H.ComponentHTML Action slots m
    render state =
        HH.div [ css [ "folder" ]]
            [ HH.div [ css [ "folder-tab" ] ] [ HH.text title ]
            , HH.div [ css [ "folder-body" ] ] [ contents ]
            ]
        where
        title = "Use Withdrawal Code"
        contents = HH.div [ css ["flex", "flex-col", "items-center", "space-y-4"] ]
            [ HH.div [ css ["flex", "flex-col"] ]
                [ HH.div_
                    [ HH.label [ HP.for "code" ] [ HH.text "Deposit code:" ]
                    , HH.input [ HP.id "code", HP.type_ HP.InputText, HE.onValueInput Code  ]
                    ]
                ]
            , case state.status of
                Result (Left err) ->
                    HH.div [ css ["errors"] ] [ HH.div [ css ["error"] ] [ HH.p_ [ HH.text $ Error.toString err ] ] ]
                Result (Right { iron, diamonds }) ->
                    HH.p_
                        [ HH.text $
                            "You deposited " <> (show iron) <> "i " <> (show diamonds) <> "d into your account"
                        ]
                Pending ->
                    HH.input [ HP.type_ HP.InputSubmit, HP.value "Redeem Deposit Code", HP.disabled true ]
                Nichts ->
                    HH.input [ HP.type_ HP.InputSubmit, HP.value "Redeem Deposit Code", HE.onClick $ \_ -> Submit ]
            ]

    handleAction :: Action -> H.HalogenM State Action () o m Unit
    handleAction = case _ of
        Initialize new ->
            H.modify_ _ { myUser = new }

        Code new ->
            H.modify_ _ { code = new }

        Submit -> do
            H.modify_ _ { status = Pending }
            code <- H.gets _.code
            res <- useDepositCode code
            H.modify_ _ { status = Result res }
