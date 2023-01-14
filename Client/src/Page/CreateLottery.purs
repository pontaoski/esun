module Page.CreateLottery
  ( component
  )
  where

import PreludeP

import Capability.Lotto (class Lottos, createLotto)
import Capability.Navigate (class Navigate, navigate)
import Data.Error as Error
import Data.Int (toNumber)
import Data.Lotto as Lotto
import Data.Lotto (Lotto)
import Data.Route (Route(..))
import Debug as Debug
import HTML as H
import Slug (Slug)
import Slug as Slug

type State =
    { title :: String
    , description :: String
    , slug :: Maybe Slug
    , ticketPrice :: Int
    , maxTicketsPerCustomer :: Int
    , houseCut :: Int
    , req :: ReqState
    }

data ReqState
    = Idle
    | Working
    | Done (Either Error Lotto)

isIdle = case _ of
    Idle -> true
    _ -> false

data Action
    = Title String
    | Description String
    | TicketPrice Int
    | MaxTicketsPerCustomer Int
    | HouseCut Int
    | Submit

component
    :: forall q i o m
    . MonadAff m
    => Lottos m
    => Navigate m
    => H.Component q i o m
component =
    H.page initialState render handleAction

    where
    initialState :: i -> State
    initialState _ =
        { title: ""
        , description: ""
        , slug: Nothing
        , ticketPrice: 2
        , maxTicketsPerCustomer: 3
        , houseCut: 10
        , req: Idle
        }

    render :: State -> H.ComponentHTML Action () m
    render state =
        H.folder title contents
        where
        title = "Create a Lottery"
        contents =
            H.div [ H.css ["flex", "flex-col", "items-center"] ]
                [ H.div [ H.css ["flex", "flex-col", "space-y-4"] ]
                    [ H.formField "title" "Title:" H.InputText state.title Title
                    , H.conditional (state.slug == Nothing && state.title /= "") $
                        H.div [ H.css ["error"] ] [ H.text "I can't make a URL out of that title" ]
                    , H.formField "description" "Description:" H.InputText state.description Description
                    , H.formField "ticketPrice" "Price per ticket:" H.InputNumber (show state.ticketPrice) (H.intHandler TicketPrice)
                    , H.formField "maxTickets" "Maximum tickets per customer:" H.InputNumber (show state.maxTicketsPerCustomer) (H.intHandler MaxTicketsPerCustomer)
                    , H.formField "houseCut" "House cut (% of pot that goes to you):" H.InputNumber (show state.houseCut) (H.intHandler HouseCut)
                    , H.input $ [ H.type_ H.InputSubmit, H.value "Create Lottery", H.onClick $ \_ -> Submit ] <> if isIdle state.req then [] else [ H.disabled true ]
                    ]
                , case state.req of
                    Done (Left err) ->
                        H.div [ H.css ["errors"] ] [ H.div [ H.css ["error"] ] [ H.p_ [ H.text $ Error.toString err ] ] ]
                    _ ->
                        H.nichts
                ]

    handleAction :: Action -> H.HalogenM State Action () o m Unit
    handleAction = case _ of
        Title new -> do
            H.modify_ _ { title = new, slug = Slug.generate new }
        Description new -> do H.modify_ _ { description = new }
        TicketPrice new -> do H.modify_ _ { ticketPrice = new }
        MaxTicketsPerCustomer new -> do H.modify_ _ { maxTicketsPerCustomer = new }
        HouseCut new -> do H.modify_ _ { houseCut = new }
        Submit -> do
            { title, description, slug, ticketPrice, maxTicketsPerCustomer, houseCut } <- H.get
            case slug of
                Just x -> do
                    H.modify_ _ { req = Working }
                    res <- createLotto
                        { title
                        , description
                        , slug: (Slug.toString x)
                        , ticketPrice
                        , maxTicketsPerCustomer
                        , houseCut: (toNumber houseCut) / (toNumber 100)
                        }
                    case res of
                        Left _ -> do
                            H.modify_ _ { req = Done res }
                        Right ok -> do
                            navigate $ Lottery (Lotto.fromString ok.slug)
                Nothing ->
                    pure unit