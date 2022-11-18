module Capability.AuditLog where

import Prelude

import Api.Endpoint (Pagination)
import Control.Monad.Cont.Trans (lift)
import Data.AuditLogEntry (AuditLogEntry)
import Data.Either (Either)
import Data.Error (Error)
import Data.Page (Page)
import Data.Username (Username)
import Halogen (HalogenM)

class Monad m <= AuditLogs m where
    getAuditLog :: Pagination -> Username -> m (Either Error (Page AuditLogEntry))

instance auditLogsHalogenM :: AuditLogs m => AuditLogs (HalogenM st act slots msg m) where
    getAuditLog pagination user = lift $ getAuditLog pagination user
