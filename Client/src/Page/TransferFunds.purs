module Page.TransferFunds
  ( component
  )
  where

import Prelude

import Capability.Funds (class Funds, transferMoney)
import Component.HTML.Utils (conditional, css)
import Data.Either (Either(..))
import Data.Error (Error)
import Data.Error as Error
import Data.Int (toNumber)
import Data.Int as Int
import Data.Maybe (Maybe(..))
import Data.Maybe as Maybe
import Data.Tuple (Tuple(..))
import Data.Username (Username(..))
import Halogen (ClassName(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

type State =
    { requestUsername :: Username
    , requestToWho :: Username
    , toWho :: Username
    , iron :: Int
    , diamond :: Int
    , error :: Maybe (Either Error Unit)
    }

data Action
    = Receive (Tuple Username Username)
    | ToWho Username
    | Iron String
    | Diamond String
    | Submit

component
    :: forall q o m
    . Funds m
    => H.Component q (Tuple Username Username) o m
component =
    H.mkComponent
        { initialState
        , render
        , eval: H.mkEval $ H.defaultEval
            { receive = \x -> Just $ Receive x
            , handleAction = handleAction
            }
        }

    where
    initialState :: (Tuple Username Username) -> State
    initialState (Tuple requestUsername toWho) =
        { requestUsername, requestToWho: toWho, toWho, iron: 0, diamond: 0, error: Nothing }

    render :: State -> H.ComponentHTML Action () m
    render state =
        HH.div [ HP.classes [ ClassName "folder" ] ]
            [ HH.div [ HP.class_ $ ClassName "folder-tab "] [ HH.text title ]
            , HH.div [ HP.class_ $ ClassName "folder-body" ] [ contents ]
            ]
        where
        title = "Transfer Funds"
        contents = HH.div [ css ["flex", "flex-col", "items-center"] ]
            [ HH.div [ css ["flex", "flex-col", "space-y-4"] ]
                [ conditional (state.requestToWho == (Username "")) $ HH.div_
                    [ HH.label [ HP.for "username" ] [ HH.text "Send funds to:" ]
                    , HH.input [ HP.id "username", HP.type_ HP.InputText, HE.onValueInput $ \x -> ToWho (Username x)  ]
                    ]
                , HH.div_
                    [ HH.label [ HP.for "ironAmount" ] [ HH.text "Iron amount:" ]
                    , HH.input [ HP.id "ironAmount", HP.type_ HP.InputNumber, HP.min (toNumber 0), HE.onValueInput Iron  ]
                    ]
                , HH.div_ 
                    [ HH.label [ HP.for "diamondAmount" ] [ HH.text "Diamond amount:" ]
                    , HH.input [ HP.id "diamondAmount", HP.type_ HP.InputNumber, HP.min (toNumber 0), HE.onValueInput Diamond ]
                    ]
                , HH.input [ HP.type_ HP.InputSubmit, HP.value "Transfer Funds", HE.onClick $ \_ -> Submit ]
                ]
            , case state.error of
                Just (Left err) ->
                    HH.div [ css ["errors"] ] [ HH.div [ css ["error"] ] [ HH.p_ [ HH.text $ Error.toString err ] ] ]
                Just (Right _) ->
                    HH.div [ ] [ HH.text ":)" ]
                Nothing ->
                    HH.text ""
            ]

    handleAction :: Action -> H.HalogenM State Action () o m Unit
    handleAction = case _ of
        Receive (Tuple requested toWho) -> do
            H.modify_ _ { requestUsername = requested, requestToWho = toWho }
        ToWho new -> do
            H.modify_ _ { toWho = new }
        Iron new -> do
            H.modify_ _ { iron = Maybe.fromMaybe 0 $ Int.fromString new }
        Diamond new -> do
            H.modify_ _ { diamond = Maybe.fromMaybe 0 $ Int.fromString new }
        Submit -> do
            to <- H.gets _.toWho
            iron <- H.gets _.iron
            diamonds <- H.gets _.diamond
            res <- transferMoney { iron, diamonds, to }
            H.modify_ _ { error = Just res }

