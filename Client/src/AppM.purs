module AppM where

import Prelude

import Api.Request (writeToken)
import Api.Request as Request
import Capability.Accounts (class Accounts)
import Capability.AuditLog (class AuditLogs)
import Capability.Auth (class Auth)
import Capability.DepositCode (class DepositCode)
import Capability.Funds (class Funds)
import Capability.Logging (class Logging, LogLevel(..))
import Capability.Logging as Logging
import Capability.Navigate (class Navigate, navigate)
import Control.Monad.Cont.Trans (lift)
import Data.Either (Either(..))
import Data.Error (Error(..), explain)
import Data.Error as Error
import Data.Maybe (Maybe(..))
import Data.Profile (MyProfile, SiteRole(..))
import Data.Route (Route(..))
import Data.Route as Route
import Effect.Aff (Aff)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Console as Console
import Halogen as H
import Halogen.Store.Monad (class MonadStore, StoreT, getStore, runStoreT, updateStore)
import Routing.Duplex (print)
import Routing.Hash (setHash)
import Safe.Coerce (coerce)
import Store (Action(..), Store)
import Store as Store
import Web.DOM.Node (baseURI)

newtype AppM a = AppM (StoreT Store.Action Store.Store Aff a)

runAppM :: forall q i o. Store.Store -> H.Component q i o AppM -> Aff (H.Component q i o Aff)
runAppM store = runStoreT store Store.reduce <<< coerce

derive newtype instance functorAppM :: Functor AppM
derive newtype instance applyAppM :: Apply AppM
derive newtype instance applicativeAppM :: Applicative AppM
derive newtype instance bindAppM :: Bind AppM
derive newtype instance monadAppM :: Monad AppM
derive newtype instance monadEffectAppM :: MonadEffect AppM
derive newtype instance monadAffAppM :: MonadAff AppM
derive newtype instance monadStoreAppM :: MonadStore Action Store AppM

instance navigateAppM :: Navigate AppM where
    navigate =
        liftEffect <<< setHash <<< print Route.routeCodec

instance accountsAppM :: Accounts AppM where
    getUser who = do
        { baseUrl } <- getStore
        res <- Request.account baseUrl who
        pure res

instance authAppM :: Auth AppM where
    loginUser token = do
        { baseUrl } <- getStore
        res <- Request.me baseUrl token
        case res of
            Left _ ->
                pure res
            Right x -> do
                liftEffect do
                    writeToken token
                navigate Home
                updateStore $ LoginUser x
                pure res

    logoutUser = do
        updateStore LogoutUser

    getCurrentUser = do
        { currentUser } <- getStore
        pure currentUser

instance loggingAppM :: Logging AppM where
    log msg = do
        { logLevel } <- getStore
        liftEffect case logLevel, Logging.reason msg of
            Prod, Logging.Debug -> pure unit
            _, _ -> Console.log $ Logging.message msg

instance depositCodeAppM :: DepositCode AppM where
    createDepositCode { iron, diamonds } = do
        { baseUrl, currentUser } <- getStore
        case currentUser of
            Just me -> do
                res <- Request.createDepositCode baseUrl me.token { iron, diamonds }
                pure res
            Nothing ->
                pure $ Left $ explain "creating deposit code" Error.AuthRequired

    useDepositCode code = do
        pure $ Left $ NotImplemented "using deposit code"
    createWithdrawalCode { password, iron, diamonds } = do
        { baseUrl, currentUser } <- getStore
        case currentUser of
            Just me -> do
                res <- Request.createWithdrawalCode baseUrl me.token { password, iron, diamonds }
                pure res
            Nothing ->
                pure $ Left $ explain "creating deposit code" Error.AuthRequired
    useWithdrawalCode code = do
        pure $ Left $ NotImplemented "using withdrawal code"

instance auditLogsAppM :: AuditLogs AppM where
    getAuditLog pagination username = do
        { baseUrl, currentUser } <- getStore
        case currentUser of
            Just me -> do
                res <- Request.auditLog baseUrl me.token username pagination
                pure res
            Nothing ->
                pure $ Left $ explain "getting audit logs" Error.AuthRequired

instance fundsAppM :: Funds AppM where
    transferMoney { iron, diamonds, to } = do
        { baseUrl, currentUser } <- getStore
        case currentUser of
            Just me -> do
                res <- Request.transferMoney baseUrl me.token to iron diamonds
                pure res
            Nothing ->
                pure $ Left $ explain "transferring funds" Error.AuthRequired

    adjustBalance { iron, diamonds, target } = do
        { baseUrl, currentUser } <- getStore
        case currentUser of
            Just me | me.role >= Teller -> do
                res <- Request.adjustBalance baseUrl me.token target { iron, diamonds }
                pure res
            Just _ -> do
                pure $ Left $ explain "adjusting balance" Error.AuthRequired
            Nothing ->
                pure $ Left $ explain "adjusting balance" Error.AuthRequired
