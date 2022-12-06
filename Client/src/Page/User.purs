module Page.User
  ( component
  )
  where

import Prelude

import Capability.Accounts (class Accounts, getUser)
import Capability.Auth (class Auth, getCurrentUser)
import Capability.Logging (class Logging, LogReason(..), log_)
import Component.HTML.Utils (css, nichts, safeHref)
import Data.Either (Either(..))
import Data.Error (Error, toString)
import Data.Maybe (Maybe(..))
import Data.Profile (MyProfile, Profile, SiteRole(..))
import Data.Route (AuthRoute(..), Route(..))
import Data.String (Pattern(..), Replacement(..))
import Data.String as String
import Data.UUID as UUID
import Data.Username (Username)
import Data.Username as Username
import Debug as Debug
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Prim.Boolean (True)

type State =
    { user :: Maybe (Either Error Profile)
    , myUser :: Maybe MyProfile
    , username :: Username
    }

data Action
    = Initialize
    | Receive Username

component
    :: forall q o m
    . Accounts m
    => Auth m
    => Logging m
    => H.Component q Username o m
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
    initialState :: Username -> State
    initialState username =
        { username, myUser: Nothing, user: Nothing }

    render state =
        HH.div [ css ["folder"] ]
            [ HH.div [ css ["folder-tab"] ] [ HH.text title ]
            , HH.div [ css ["folder-body"] ] [ contents ]
            ]
        where
        title = Username.toString state.username
        contents = HH.div [ css ["flex", "flex-col", "items-center", "py-2"] ]
            case state.user of
                Nothing ->
                    [ HH.text "Loading..."
                    ]
                Just (Left err) ->
                    [ HH.text $ "Failed to get user :/ " <> toString err
                    ]
                Just (Right user) ->
                    [ HH.img
                        [ HP.src $ "https://crafthead.net/bust/" <> (String.toLower $ String.replaceAll (Pattern "-") (Replacement "") $ UUID.toString user.id)
                        , css $ if not user.created then ["grayscale", "py-2"] else ["py-2"]
                        ]
                    , if not user.created then
                        HH.p [ css ["text-center", "py-2"] ]
                            [ HH.text "This user has not created an account yet."
                            , HH.br_
                            , HH.text "You will still be able to transfer funds to them, but they will not be notified of it."
                            ]
                    else
                        nichts
                    , HH.div [ css ["space-y-4", "w-full" ] ]
                        [ HH.div [ css ["flex", "flex-row", "space-x-4"] ]
                            [ HH.a [ css ["button"], safeHref $ AuthRequired $ TransferFunds user.username ] [ HH.text "Transfer Funds" ]
                            , HH.a [ css ["button"] ] [ HH.text "Shops" ]
                            ]
                        , if Just user.id == map _.id state.myUser then
                            HH.div [ css ["flex", "flex-row", "space-x-4"] ]
                                [ HH.a [ css ["button"], safeHref $ AuthRequired $ AuditLog user.username { page: Nothing, per: Nothing } ] [ HH.text "Audit Log" ]
                                , HH.a [ css ["button"], safeHref $ AuthRequired $ CreateDepositCode ] [ HH.text "Create a Deposit Code" ]
                                , HH.a [ css ["button"], safeHref $ AuthRequired $ UseDepositCode ] [ HH.text "Redeem a Deposit Code" ]
                                , HH.a [ css ["button"], safeHref $ AuthRequired $ UseWithdrawalCode ] [ HH.text "Redeem a Withdrawal Code" ]
                                ]
                        else
                            nichts
                        , if (map (\x -> x >= Teller) (map _.role state.myUser)) == Just true then
                            HH.div [ css ["flex", "flex-row", "space-x-4"] ]
                                [ HH.a [ css ["button"], safeHref $ AuthRequired $ AdjustBalance user.username ] [ HH.text "Adjust Balance" ]
                                , HH.a [ css ["button"], safeHref $ AuthRequired $ CreateWithdrawalCode ] [ HH.text "Create Withdrawal Code" ]
                                ]
                        else
                            nichts
                        ]
                    ]

    handleAction :: Action -> H.HalogenM State Action () o m Unit
    handleAction = case _ of
        Receive username -> do
            ousername <- H.gets _.username
            if ousername /= username then do
                H.modify_ _ { user = Nothing, username = username }
                who <- getUser username
                me <- getCurrentUser
                H.modify_ _ { user = Just who, myUser = me }
            else do
                pure unit
        Initialize -> do
            username <- H.gets _.username
            who <- getUser username
            me <- getCurrentUser
            H.modify_ _ { user = Just who, myUser = me }

