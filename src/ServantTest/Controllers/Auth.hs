{-# LANGUAGE OverloadedLabels #-}

module ServantTest.Controllers.Auth where

import Control.Monad
import Common.HasVal.Class

import ServantTest.Models.User
import ServantTest.Db.Transactor (Transactor(..))
import ServantTest.Db.User as Db.User

type ControllerConstraints env t m action = (HasVal "transactor" env t, Transactor t m action, UserDb action)

checkUserLogin :: ControllerConstraints env t m action => LoginInput -> env -> m (Maybe User)
checkUserLogin (LoginInput login password) env = do
  let transactor = #transactor env
  maybeUser <- transact transactor $ Db.User.findUserByLogin login
  return $ do user <- maybeUser
              guard (password == userPassword user)
              return user
