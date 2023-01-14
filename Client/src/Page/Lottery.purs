module Page.Lottery
    ( component
    ) where

import PreludeP

import Capability.Lotto (class Lottos, buyTicket, lottoInfo)
import Control.Monad.Cont.Trans (lift)
import Data.Error as Error
import Data.Int (toNumber)
import Data.Interval (millisecond)
import Data.Lotto (Lotto, Lottoname)
import Effect.Aff (Milliseconds(..))
import Effect.Aff as Aff
import HTML as H

type State =
    { lotto :: Maybe (Either Error Lotto)
    , lottoname :: Lottoname
    , error :: Maybe Error
    , showTicketBought :: Boolean
    }

data Action
    = Receive Lottoname
    | Initialize
    | BuyTicket
    | RollWinner

component
    :: forall q o m
    . MonadAff m
    => Lottos m
    => H.Component q Lottoname o m
component =
    H.mkComponent
        { initialState
        , render
        , eval: H.mkEval $ H.defaultEval
            { handleAction = handleAction
            , initialize = Just Initialize
            , receive = \x -> Just $ Receive x
            }
        }

    where
    initialState :: Lottoname -> State
    initialState lottoname =
        { lotto: Nothing, lottoname, error: Nothing, showTicketBought: false }

    render :: State -> H.ComponentHTML Action () m
    render state =
        H.folder title contents
        where
        title = "Lottery"
        contents = H.div [ H.css ["flex", "flex-col", "items-center", "space-y-2"] ]
            case state.lotto of
                Nothing ->
                    [ H.text "Loading..."
                    ]
                Just (Left err) ->
                    [ H.text $ "Failed to get lottery :/ " <> Error.toString err
                    ]
                Just (Right lotto) ->
                    [ H.span [ H.css ["text-lg"] ] [ H.text $ lotto.title ]
                    , H.text lotto.description
                    , H.div [ H.css ["flex", "flex-row", "space-x-2", "w-full"] ]
                        (map box
                            [ col [ txt "Costs", big $ show lotto.ticketPrice<>"d", txt "per ticket" ]
                            , col [ txt "Up to", big $ show lotto.maxTicketsPerCustomer, txt "tickets a customer" ]
                            , col [ txt "The house takes", big $ (show $ lotto.houseCut*(toNumber 100))<>"%", txt "of the pot" ]
                            ]
                        )
                    , H.div [ H.css ["flex", "flex-row", "space-x-2", "my-2"] ]
                        [ H.btn "Buy Ticket" BuyTicket
                        , H.btn "Roll Winner" RollWinner
                        ]
                    , H.conditional state.showTicketBought $
                        H.div_ [ H.text "Ticket bought!" ]
                    ]

        txt text =
            H.span [ H.css ["text-sm"] ] [ H.text text ]
        big text =
            H.span [ H.css ["text-lg"] ] [ H.text text ]
        col items =
            H.div [ H.css ["flex", "flex-col", "items-center"] ] items
        box inner =
            H.div [ H.css ["bg-slate-100", "border-solid", "border", "border-slate-400", "rounded", "px-4", "py-2", "w-1/3"] ] [inner]

    handleAction :: Action -> H.HalogenM State Action () o m Unit
    handleAction = case _ of
        Initialize -> do
            H.modify_ _ { lotto = Nothing }
            lname <- H.gets _.lottoname
            lotto <- lottoInfo lname
            H.modify_ _ { lotto = Just lotto }
        Receive x -> do
            H.modify_ _ { lottoname = x }
            handleAction Initialize
        BuyTicket -> do
            lname <- H.gets _.lottoname
            res <- buyTicket lname
            H.modify_ _ { error = Nothing }
            H.modify_ _ { showTicketBought = false }
            case res of
                Left err ->
                    H.modify_ _ { error = Just err }
                Right _ -> do
                    H.modify_ _ { showTicketBought = true }
                    H.liftAff $ Aff.delay (Milliseconds 5000.0)
                    H.modify_ _ { showTicketBought = false }
        RollWinner -> do
            lname <- H.gets _.lottoname
            res <- buyTicket lname
            pure unit