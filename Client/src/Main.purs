module Main where

import Prelude

import Api.Request (BaseURL(..))
import App.Button as Button
import AppM (runAppM)
import Component.Router as Router
import Data.Maybe (Maybe(..))
import Data.Route (Route, routeCodec)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Halogen (liftEffect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.VDom.Driver (runUI)
import Routing.Duplex (parse)
import Routing.Hash (matchesWith)
import Routing.Match (Match)
import Store (LogLevel(..), Store)

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody

  let
    baseUrl = BaseURL "http://localhost:8080"
    logLevel = Dev

  let
    initialStore :: Store
    initialStore = { baseUrl, currentUser: Nothing, logLevel }

  rootComponent <- runAppM initialStore Router.component
  halogenIO <- runUI rootComponent unit body

  void $ liftEffect $ matchesWith (parse routeCodec) \old new ->
    when (old /= Just new) $ launchAff_ do
      _response <- halogenIO.query $ H.mkTell $ Router.Navigate new
      pure unit
