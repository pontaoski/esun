module Page.AuditLog where

import PreludeP

import Api.Endpoint (Pagination)
import Capability.AuditLog (class AuditLogs, getAuditLog)
import Component.HTML.Utils (css, customerLink)
import Data.AuditLogEntry (AuditLogEntry(..))
import Data.AuditLogEntry as ALE
import Data.Error as Error
import Data.Page (Page)
import Data.Tuple (Tuple(..))
import Data.Username (Username)
import Data.Username as Username
import Halogen as H
import Halogen.HTML as HH

type State =
    { username :: Username
    , pagination :: Pagination
    , pages :: Maybe (Either Error (Page AuditLogEntry))
    }

data Action
    = Initialize
    | Receive Username Pagination

component
    :: forall q o m
    . AuditLogs m
    => H.Component q (Tuple Username Pagination) o m
component =
    H.mkComponent
        { initialState
        , render
        , eval: H.mkEval $ H.defaultEval
            { handleAction = handleAction
            , initialize = Just Initialize
            , receive = receive
            }
        }
    where
    initialState :: Tuple Username Pagination -> State
    initialState (Tuple username pagination) =
        { username, pagination, pages: Nothing }

    receive :: (Tuple Username Pagination) -> Maybe Action
    receive (Tuple x y) =
        Just $ Receive x y

    render :: State -> H.ComponentHTML Action () m
    render state =
        HH.div [ css ["folder"] ]
            [ HH.div [ css ["folder-tab"] ] [ HH.text title ]
            , HH.div [ css ["folder-body"] ] [ contents ]
            ]
        where
        title = Username.toString state.username
        contents = HH.div [ css ["flex", "flex-col", "items-center", "py-2", "space-y-2"] ]
            case state.pages of
                Nothing ->
                    [ HH.text "Loading..."
                    ]
                Just (Left err) ->
                    [ HH.text $ "Failed to get user :/ " <> Error.toString err
                    ]
                Just (Right { items, metadata }) ->
                    map (displayEntry >>> coatEntry) items

        coatEntry :: forall i w. HH.HTML i w -> HH.HTML i w
        coatEntry entry =
            HH.div [ css ["bg-white", "px-4", "py-2", "rounded", "shadow", "w-full"] ]
                [ entry
                ]

        displayEntry :: forall i w. AuditLogEntry -> HH.HTML i w
        displayEntry entry =
            case entry of
                MoneyTransfer {iron, diamonds, from, to} ->
                    HH.span_
                        [ customerLink from
                        , HH.text $ " sent " <> (show iron) <> "i"
                                             <> (show diamonds) <> "d"
                                             <> " to "
                        , customerLink to
                        ]
                BalanceAdjustment { iron, diamonds, target, teller } ->
                    HH.span_
                        [ customerLink teller
                        , HH.text " adjusted "
                        , customerLink target
                        , HH.text $ "'s balance by " <> (show iron) <> "i"
                                             <> (show diamonds) <> "d"
                        ]
                ALE.CreateDepositCode { code, iron, diamonds, creator } ->
                    HH.span_
                        [ customerLink creator
                        , HH.text $ " created a deposit code for "
                            <> (show iron) <> "i"
                            <> (show diamonds) <> "d"
                        , HH.text $ " (" <> code <> ")"
                        ]
                ALE.CreateWithdrawalCode { code, iron, diamonds, creator } ->
                    HH.span_
                        [ customerLink creator
                        , HH.text $ " created a withdrawal code for "
                            <> (show iron) <> "i"
                            <> (show diamonds) <> "d"
                        , HH.text $ " (" <> code <> ")"
                        ]
                ALE.UseDepositCode { code, iron, diamonds, user } ->
                    HH.span_
                        [ customerLink user
                        , HH.text $ " used a deposit code for "
                            <> (show iron) <> "i"
                            <> (show diamonds) <> "d"
                        , HH.text $ " (" <> code <> ")"
                        ]
                ALE.UseWithdrawalCode { code, iron, diamonds, user } ->
                    HH.span_
                        [ customerLink user
                        , HH.text $ " used a withdrawal code for "
                            <> (show iron) <> "i"
                            <> (show diamonds) <> "d"
                        , HH.text $ " (" <> code <> ")"
                        ]

    handleAction :: Action -> H.HalogenM State Action () o m Unit
    handleAction = case _ of
        Initialize -> fetchItems
        Receive username pagination -> do
            H.modify_ _ { username = username, pagination = pagination }
            fetchItems

    fetchItems :: H.HalogenM State Action () o m Unit
    fetchItems = do
        H.modify_ _ { pages = Nothing }
        username <- H.gets _.username
        pagination <- H.gets _.pagination
        res <- getAuditLog pagination username
        H.modify_ _ { pages = Just res }
        pure unit