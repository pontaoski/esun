module Component.HTML.Utils where

import Prelude

import Data.Route (Route, routeCodec)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Routing.Duplex (print)

css :: forall r i. Array String -> HH.IProp (class :: String | r) i
css names = HP.classes $ map HH.ClassName names

nichts :: forall i w. HH.HTML i w
nichts =
    HH.text ""

safeHref :: forall r i. Route -> HH.IProp ( href :: String | r ) i
safeHref =
    HP.href <<< append "#" <<< print routeCodec
