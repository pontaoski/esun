module HTML
  ( module Component.HTML.Utils
  , module Halogen
  , module Halogen.HTML
  , module Halogen.HTML.Events
  , module Halogen.HTML.Properties
  , page
  )
  where

import Component.HTML.Utils
import Halogen
import Halogen.HTML hiding (title)
import Halogen.HTML.Properties hiding (style)
import Halogen.HTML.Events hiding (handler)

import Data.Unit (Unit)

page :: forall q i o m state action slots.
    (i -> state) ->
    (state -> ComponentHTML action slots m) ->
    (action -> HalogenM state action slots o m Unit) ->
    Component q i o m
page initialState render handleAction =
    mkComponent
        { initialState
        , render
        , eval: mkEval defaultEval
            { handleAction = handleAction
            }
        }
