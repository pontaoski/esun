module Component.Router where

import Prelude

import Capability.Auth (class Auth, getCurrentUser, loginUser)
import Capability.Navigate (class Navigate, navigate)
import Component.Header as Header
import Component.Utils (OpaqueSlot)
import Data.Either (hush)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Profile (MyProfile)
import Data.Route (AuthRoute(..), Route(..), routeCodec)
import Data.Token (Token)
import Effect.Aff.Class (class MonadAff)
import Halogen (liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.Store.Monad (class MonadStore)
import Page.CreateDepositCode as CreateDepositCode
import Page.Home as Home
import Routing.Duplex as RD
import Routing.Hash (getHash)
import Store as Store
import Type.Proxy (Proxy(..))

data Query a = Navigate Route a

type State =
    { route :: Maybe Route
    , myUser :: Maybe MyProfile
    }

data Action
    = Initialize
    | GetMe Token

type ChildSlots =
    ( home :: OpaqueSlot Unit
    , header :: OpaqueSlot Unit
    , createDepositCode :: OpaqueSlot Unit
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
        { initialState: \_ -> { route: Nothing, myUser: Nothing }
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
            me <- getCurrentUser
            H.modify_ _ { myUser = me }

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
    render { route, myUser } =
        HH.div_
            [ HH.slot_ (Proxy :: _ "header") unit Header.component unit
            ,
                case route of
                    Just r -> case r of
                        Home ->
                            HH.slot_ (Proxy :: _ "home") unit Home.component unit
                        AuthCallback _ -> do
                            HH.div_ [ HH.text "Logging in..." ]
                        AuthRequired sub ->
                            case myUser of
                                Just x ->
                                    case sub of
                                        CreateDepositCode ->
                                            HH.slot_ (Proxy :: _ "createDepositCode") unit CreateDepositCode.component x
                                Nothing ->
                                    HH.div_ [ HH.text "Auth required" ]
                    Nothing ->
                        HH.div_ [ HH.text "Page not found" ]
            ]
