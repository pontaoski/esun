module Component.Router where

import Prelude

import Capability.Auth (class Auth, loginUser)
import Capability.Navigate (class Navigate, navigate)
import Component.Utils (OpaqueSlot)
import Data.Either (hush)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Route (Route(..), routeCodec)
import Data.Token (Token)
import Effect.Aff.Class (class MonadAff)
import Halogen (liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.Store.Monad (class MonadStore)
import Page.Home as Home
import Routing.Duplex as RD
import Routing.Hash (getHash)
import Store as Store
import Type.Proxy (Proxy(..))

data Query a = Navigate Route a

type State =
    { route :: Maybe Route
    }

data Action
    = Initialize
    | GetMe Token

type ChildSlots =
    ( home :: OpaqueSlot Unit
    )

component
    :: forall m
    . MonadAff m
    => MonadStore Store.Action Store.Store m
    => Navigate m
    => Auth m
    => H.Component Query Unit Void m
component =
    H.mkComponent
        { initialState: \_ -> { route: Nothing }
        , render
        , eval: H.mkEval $ H.defaultEval
            { handleQuery = handleQuery
            , handleAction = handleAction
            , initialize = Just Initialize
            }
        }
    where
    handleAction :: Action -> H.HalogenM State Action ChildSlots Void m Unit
    handleAction = case _ of
        Initialize -> do
            initialRoute <- hush <<< (RD.parse routeCodec) <$> liftEffect getHash
            navigate $ fromMaybe Home initialRoute

        GetMe token -> do
            loginUser token *> pure unit

    handleQuery :: forall a. Query a -> H.HalogenM State Action ChildSlots Void m (Maybe a)
    handleQuery = case _ of
        Navigate dest@(AuthCallback token) a -> do
            void $ H.fork $ handleAction $ (GetMe token)
            { route } <- H.get
            when (route /= Just dest) do
                H.modify_ _ { route = Just dest }
            pure (Just a)
        Navigate dest a -> do
            { route } <- H.get
            when (route /= Just dest) do
                H.modify_ _ { route = Just dest }
            pure (Just a)

    render :: State -> H.ComponentHTML Action ChildSlots m
    render { route } = case route of
        Just r -> case r of
            Home ->
                HH.slot_ (Proxy :: _ "home") unit Home.component unit
            AuthCallback _ -> do
                HH.div_ [ HH.text "Logging in..." ]
        Nothing ->
            HH.div_ [ HH.text "Page not found" ]
