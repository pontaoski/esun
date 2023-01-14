module Component.HTML.Utils where

import Prelude

import Data.AuditLogEntry (AuditLogEntry, AuditLogCustomer)
import Data.Error (Error)
import Data.Error as Error
import Data.Int as Int
import Data.Maybe as Maybe
import Data.Number as Number
import Data.Route (Route(..), routeCodec)
import Data.Username (Username(..))
import Data.Username as Username
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
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

folder :: forall i w. String -> HH.HTML i w -> HH.HTML i w
folder title body =
    HH.div [ css ["folder"] ]
        [ HH.div [ css ["folder-tab"] ] [ HH.text title ]
        , HH.div [ css ["folder-body"] ] [ body ]
        ]

formField :: forall i w. String -> String -> HP.InputType -> String -> (String -> w) -> HH.HTML i w
formField id label inputType value onEv =
    HH.div_
        [ HH.label [ HP.for id ] [ HH.text label ]
        , HH.input [ HP.id id, HP.type_ inputType, HP.value value, HE.onValueInput onEv ]
        ]

intHandler :: forall a. (Int -> a) -> (String -> a)
intHandler cb =
    \new -> cb $ Maybe.fromMaybe 0 $ Int.fromString new

numHandler :: forall a. (Number -> a) -> (String -> a)
numHandler cb =
    \new -> cb $ Maybe.fromMaybe (Int.toNumber 0) $ Number.fromString new

btn :: forall i w. String -> w -> HH.HTML i w
btn lbl onClick =
    HH.a [ css ["button"], HE.onClick \_ -> onClick ] [ HH.text lbl ]

errors :: forall i w. Error -> HH.HTML i w
errors err =
    HH.div [ css ["errors"] ] [ HH.div [ css ["error"] ] [ HH.p_ [ HH.text $ Error.toString err ] ] ]
