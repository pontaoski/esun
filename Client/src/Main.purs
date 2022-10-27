module Main where

import Prelude

import Api.Request (BaseURL(..), readToken)
import Api.Request as Request
import AppM (runAppM)
import Capability.Logging (LogLevel(..))
import Component.Router as Router
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Route (routeCodec)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Halogen (liftEffect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.VDom.Driver (runUI)
import Routing.Duplex (parse)
import Routing.Hash (matchesWith)
import Store (Store)

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody

  let
    baseUrl = BaseURL "http://localhost:8080"
    logLevel = Dev

  currentUser <- liftEffect readToken >>= case _ of
    Nothing ->
      pure Nothing

    Just token -> do
      Request.me baseUrl token >>= case _ of
        Left _ -> pure Nothing
        Right profile -> pure $ Just profile

  let
    initialStore :: Store
    initialStore = { baseUrl, currentUser, logLevel }

  rootComponent <- runAppM initialStore Router.component
  halogenIO <- runUI rootComponent unit body

  void $ liftEffect $ matchesWith (parse routeCodec) \old new ->
    when (old /= Just new) $ launchAff_ do
      _response <- halogenIO.query $ H.mkTell $ Router.Navigate new
      pure unit
