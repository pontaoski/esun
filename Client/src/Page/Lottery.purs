module Page.Lottery
    ( component
    ) where

import Prelude

import Capability.Lotto (class Lottos, lottoInfo)
import Component.HTML.Utils (conditional, css)
import Data.Either (Either(..))
import Data.Error (Error)
import Data.Error as Error
import Data.Lotto (Lotto, Lottoname(..))
import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH

type State =
    { lotto :: Maybe (Either Error Lotto)
    }

data Action
    = Initialize Lottoname

component
    :: forall q o m
    . MonadAff m
    => Lottos m
    => H.Component q Lottoname o m
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
    initialState :: Lottoname -> State
    initialState _ =
        { lotto: Nothing }

    render :: State -> H.ComponentHTML Action () m
    render state =
        HH.div [ css ["folder"] ]
            [ HH.div [ css ["folder-tab"] ] [ HH.text title ]
            , HH.div [ css ["folder-body"] ] [ contents ]
            ]
        where
        title = "Lottery"
        contents = HH.div [ css ["flex", "flex-col", "items-center"] ]
            case state.lotto of
                Nothing ->
                    [ HH.text "Loading..."
                    ]
                Just (Left err) ->
                    [ HH.text $ "Failed to get lottery :/ " <> Error.toString err
                    ]
                Just (Right lotto) ->
                    [ HH.text $ lotto.title
                    ]

    handleAction :: Action -> H.HalogenM State Action () o m Unit
    handleAction = case _ of
        Initialize str -> do
            lotto <- lottoInfo str
            H.modify_ _ { lotto = Just lotto }
