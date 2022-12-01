module Page.CreateWithdrawalCode where

import Prelude

import Capability.DepositCode (class DepositCode, createWithdrawalCode)
import Capability.Navigate (class Navigate, navigate)
import Component.HTML.Utils (css)
import Data.Either (Either(..))
import Data.Error (Error)
import Data.Error as Error
import Data.Int (toNumber)
import Data.Int as Int
import Data.Maybe (Maybe(..))
import Data.Maybe as Maybe
import Data.Profile (MyProfile)
import Data.Route (AuthRoute(..), Route(..))
import Halogen (ClassName(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

type State =
    { myUser :: MyProfile
    , iron :: Int
    , diamond :: Int
    , password :: String
    , error :: Maybe Error
    }

data Action
    = Initialize MyProfile
    | Iron String
    | Diamond String
    | Password String
    | Submit

component
    :: forall q o m
    . DepositCode m
    => Navigate m
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
        { myUser, iron: 0, diamond: 0, password: "", error: Nothing }

    render state =
        HH.div [ HP.classes [ ClassName "folder" ] ]
            [ HH.div [ HP.class_ $ ClassName "folder-tab "] [ HH.text title ]
            , HH.div [ HP.class_ $ ClassName "folder-body" ] [ contents ]
            ]
        where
        title = "Create Withdrawal Code"
        contents = HH.div [ css ["flex", "flex-col", "items-center"] ]
            [ HH.div [ css ["flex", "flex-col", "space-y-4"] ]
                [ HH.div_
                    [ HH.label [ HP.for "ironAmount" ] [ HH.text "Iron amount:" ]
                    , HH.input [ HP.id "ironAmount", HP.type_ HP.InputNumber, HP.min (toNumber 0), HE.onValueInput Iron  ]
                    ]
                , HH.div_ 
                    [ HH.label [ HP.for "diamondAmount" ] [ HH.text "Diamond amount:" ]
                    , HH.input [ HP.id "diamondAmount", HP.type_ HP.InputNumber, HP.min (toNumber 0), HE.onValueInput Diamond ]
                    ]
                , HH.div_ 
                    [ HH.label [ HP.for "password" ] [ HH.text "Password:" ]
                    , HH.input [ HP.id "password", HP.type_ HP.InputNumber, HP.min (toNumber 0), HE.onValueInput Diamond ]
                    ]
                , HH.input [ HP.type_ HP.InputSubmit, HP.value "Create Withdrawal Code", HE.onClick $ \_ -> Submit ]
                ]
            , case state.error of
                Just err ->
                    HH.div [ css ["errors"] ] [ HH.div [ css ["error"] ] [ HH.p_ [ HH.text $ Error.toString err ] ] ]
                Nothing ->
                    HH.text ""
            , HH.p [ css ["max-w-lg"] ]
                [ HH.text
                    """
                    You can create a withdrawal code which will deduct the given amount of funds from the redeemer's
                    account. In response to the redemption of a code, the redeemer will be shown the password you give
                    here. This is typically a password to a NameLayer group or a secret used to create a book and quill
                    to sell to a shop chest.
                    """
                ]
            ]

    handleAction :: Action -> H.HalogenM State Action () o m Unit
    handleAction = case _ of
        Initialize new -> do
            H.modify_ _ { myUser = new }

        Iron new -> do
            H.modify_ _ { iron = Maybe.fromMaybe 0 $ Int.fromString new }

        Diamond new -> do
            H.modify_ _ { diamond = Maybe.fromMaybe 0 $ Int.fromString new }

        Password new -> do
            H.modify_ _ { password = new }

        Submit -> do
            iron <- H.gets _.iron
            diamonds <- H.gets _.diamond
            password <- H.gets _.password
            res <- createWithdrawalCode { password, diamonds, iron }
            case res of
                Left err -> do
                    H.modify_ _ { error = Just err }
                Right ok -> do
                    navigate $ AuthRequired $ WithdrawalCodeCreated ok
                    H.modify_ _ { error = Nothing }
