{-# LANGUAGE RecordWildCards #-}

module ServantTest.Db.User
  ( UserDb(..)
  ) where

import Prelude hiding (id)
import Data.Maybe (fromJust, listToMaybe)
import Database.SQLite.Simple

import ServantTest.Db.SQLite
import qualified ServantTest.Models.User as M.User
import ServantTest.Models.User ( User(..)
                               , NewUser(..)
                               , Login
                               , textToLogin
                               , textToPassword
                               , loginToText
                               , passwordToText
                               )

newtype DbUser = DbUser { dbToUser :: User }
instance FromRow DbUser where
  fromRow = DbUser <$> user
    where user = User <$> id <*> login <*> password
          id = field
          login = (textToLogin <$> field)
          password = (textToPassword <$> field)

newtype DbNewUser = DbNewUser NewUser
instance ToRow DbNewUser where
  toRow (DbNewUser NewUser {..}) = toRow ( loginToText newLogin
                                         , passwordToText newPassword
                                         )

class UserDb action where
  initDB :: action ()
  listUsers :: action [User]
  getUser :: Integer -> action (Maybe User)
  createUser :: M.User.NewUser -> action User
  findUserByLogin :: M.User.Login -> action (Maybe User)

instance UserDb SQLiteAction where
  initDB :: SQLiteAction ()
  initDB = SQLiteAction $ \conn ->
    execute_ conn
      "CREATE TABLE IF NOT EXISTS users (id integer not null primary key, login text not null, password text not null)"

  listUsers :: SQLiteAction [User]
  listUsers = SQLiteAction listUsers'

  getUser :: Integer -> SQLiteAction (Maybe User)
  getUser rowId = SQLiteAction $ getUser' rowId

  createUser :: M.User.NewUser -> SQLiteAction User
  createUser newUser = SQLiteAction $ createUser' newUser

  findUserByLogin :: M.User.Login -> SQLiteAction (Maybe User)
  findUserByLogin login = SQLiteAction $ findUserByLogin' login

listUsers' :: Connection -> IO [User]
listUsers' conn = do
  results <- query conn "SELECT id, login, password FROM users" ()
  return . map dbToUser $ results

getUser' :: Integer -> Connection -> IO (Maybe User)
getUser' rowId conn = do
  results <- query conn "SELECT id, login, password FROM users WHERE id = ?" [rowId]
  let maybeDbUser = listToMaybe results
      maybeUser = dbToUser <$> maybeDbUser
  return maybeUser

createUser' :: M.User.NewUser -> Connection -> IO User
createUser' newUser conn = do
    execute conn "INSERT INTO users (login, password) values (?, ?)" (DbNewUser newUser)
    rowId <- lastInsertRowId conn
    fromJust <$> getUser' (fromIntegral rowId) conn

findUserByLogin' :: Login -> Connection -> IO (Maybe User)
findUserByLogin' login conn = do
  results <- query conn "SELECT id, login, password FROM users WHERE login = ?" [loginToText login]
  let maybeDbUser = listToMaybe results
      maybeUser = dbToUser <$> maybeDbUser
  return maybeUser
