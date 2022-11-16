module Page.Home where

import Prelude

import Capability.Auth (class Auth, getCurrentUser)
import Data.Foldable (fold)
import Data.Maybe (Maybe(..))
import Data.Profile (MyProfile)
import Data.String (Pattern(..), Replacement(..))
import Data.String as String
import Data.UUID as UUID
import Data.Username as Username
import Effect.Aff.Class (class MonadAff)
import Halogen (ClassName(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

data Action
  = Initialize

type State =
    { myUser :: Maybe MyProfile
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
        { myUser: Nothing
        }

    render :: forall slots. State -> H.ComponentHTML Action slots m
    render state =
        HH.div [ HP.classes [ ClassName "folder" ] ]
            [ HH.div [ HP.class_ $ ClassName "folder-tab "] [ HH.text title ]
            , HH.div [ HP.class_ $ ClassName "folder-body" ] [ contents ]
            ]
        where
        title = case state.myUser of
            Just me ->
                Username.toString me.username
            Nothing ->
                "Homepage"
        contents = case state.myUser of
            Just me ->
                HH.div_
                    [ HH.p_ [ HH.text $ fold [ "home page ", Username.toString me.username ]
                            , HH.img [ HP.src $ "https://crafthead.net/bust/" <> (String.toLower $ String.replaceAll (Pattern "-") (Replacement "") $ UUID.toString me.id) ]
                            ]
                    ]
            Nothing ->
                HH.div_
                    [ HH.p_ [ HH.text "home page"] ]

    handleAction :: forall slots. Action -> H.HalogenM State Action slots o m Unit
    handleAction = case _ of
        Initialize -> do
            user <- getCurrentUser
            H.modify_ _ { myUser = user }