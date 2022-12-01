module Component.HTML.Utils where

import Prelude

import Data.AuditLogEntry (AuditLogEntry, AuditLogCustomer)
import Data.Route (Route(..), routeCodec)
import Data.Username (Username(..))
import Data.Username as Username
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Routing.Duplex (print)

css :: forall r i. Array String -> HH.IProp (class :: String | r) i
css names = HP.classes $ map HH.ClassName names

nichts :: forall i w. HH.HTML i w
nichts =
    HH.text ""

customerLink :: forall i w. AuditLogCustomer -> HH.HTML i w
customerLink rec =
    HH.a [ safeHref $ User rec.user.username, css ["linkbutton", "inline-flex", "items-baseline", "space-x-1"] ]
        [ HH.img [ HP.src $ "https://crafthead.net/avatar/" <> Username.toString rec.user.username, css ["self-center", "inline", "aspect-square", "h-5"] ]
        , HH.span_ [ HH.text $ Username.toString rec.user.username ]
        ]

safeHref :: forall r i. Route -> HH.IProp ( href :: String | r ) i
safeHref =
    HP.href <<< append "#" <<< print routeCodec

conditional :: forall i w. Boolean -> HH.HTML i w -> HH.HTML i w
conditional cond html =
    if cond then
        html
    else
        HH.text ""
