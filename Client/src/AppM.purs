module AppM where

import Prelude

import Api.Request (writeToken)
import Api.Request as Request
import Capability.Auth (class Auth)
import Capability.Logging (class Logging, LogLevel(..))
import Capability.Logging as Logging
import Capability.Navigate (class Navigate, navigate)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
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

instance authAppM :: Auth AppM where
    loginUser token = do
        { baseUrl } <- getStore
        Request.me baseUrl token >>= case _ of
            Left _ -> do pure Nothing
            Right profile -> do
                liftEffect do
                    writeToken token
                navigate Home
                updateStore $ LoginUser profile
                pure (Just profile)

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
