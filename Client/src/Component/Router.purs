module Component.Router where

import Prelude

import Capability.Accounts (class Accounts)
import Capability.AuditLog (class AuditLogs)
import Capability.Auth (class Auth, getCurrentUser, loginUser)
import Capability.DepositCode (class DepositCode)
import Capability.Funds (class Funds)
import Capability.Logging (class Logging, Log(..), LogReason(..), log, log_)
import Capability.Navigate (class Navigate, navigate)
import Component.HTML.Utils (css)
import Component.Header as Header
import Component.Utils (OpaqueSlot)
import Data.Either (hush)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Profile (MyProfile)
import Data.Route (AuthRoute(..), Route(..), routeCodec)
import Data.Token (Token)
import Data.Tuple (Tuple(..))
import Data.Username (Username(..))
import Effect.Aff.Class (class MonadAff)
import Halogen (liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.Store.Monad (class MonadStore)
import Page.AuditLog as AuditLog
import Page.CreateDepositCode as CreateDepositCode
import Page.Home as Home
import Page.TransferFunds as TransferFunds
import Page.User as User
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
    , user :: OpaqueSlot Unit
    , auditLog :: OpaqueSlot Unit
    , transferFunds :: OpaqueSlot Unit
    )

component
    :: forall m
    . MonadAff m
    => MonadStore Store.Action Store.Store m
    => Navigate m
    => Auth m
    => DepositCode m
    => Accounts m
    => Logging m
    => AuditLogs m
    => Funds m
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
                HH.div [ css ["folder-stack"] ]
                case route of
                    Just r -> case r of
                        Home ->
                            [ HH.slot_ (Proxy :: _ "home") unit Home.component unit ]
                        User who ->
                            [ HH.slot_ (Proxy :: _ "user") unit User.component who ]
                        AuthCallback _ -> do
                            [ HH.div_ [ HH.text "Logging in..." ] ]
                        AuthRequired sub ->
                            case myUser of
                                Just x ->
                                    case sub of
                                        CreateDepositCode ->
                                            [ HH.slot_ (Proxy :: _ "user") unit User.component x.username
                                            , HH.slot_ (Proxy :: _ "createDepositCode") unit CreateDepositCode.component x
                                            ]
                                        TransferFunds username ->
                                            [ HH.slot_ (Proxy :: _ "user") unit User.component username
                                            , HH.slot_ (Proxy :: _ "transferFunds") unit TransferFunds.component (Tuple username $ if x.username == username then Username "" else username)
                                            ]
                                        DepositCodeCreated code ->
                                            [ HH.slot_ (Proxy :: _ "user") unit User.component x.username
                                            , HH.slot_ (Proxy :: _ "createDepositCode") unit CreateDepositCode.component x
                                            , HH.div [ css ["folder"] ]
                                                [ HH.div [ css ["folder-tab"] ] [ HH.text "Deposit Code Successfully Created" ]
                                                , HH.div [ css ["folder-body", "space-y-4"] ]
                                                    [ HH.p [ css ["w-full", "text-center", "text-3xl"] ] [ HH.text code ]
                                                    , HH.p_ [ HH.text "You can now give this deposit code to someone else." ]
                                                    ]
                                                ]
                                            ]
                                        AuditLog username pagination ->
                                            [ HH.slot_ (Proxy :: _ "user") unit User.component username
                                            , HH.slot_ (Proxy :: _ "auditLog") unit AuditLog.component (Tuple username pagination)
                                            ]
                                Nothing ->
                                    [ HH.div_ [ HH.text "Auth required" ] ]
                    Nothing ->
                        [ HH.div_ [ HH.text "Page not found" ] ]
            ]
