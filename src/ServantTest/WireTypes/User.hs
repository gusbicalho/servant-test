{-# LANGUAGE TemplateHaskell #-}

module ServantTest.WireTypes.User where

import Servant
import Data.Aeson.TH
import qualified Data.Text as T
import Common.Util.AesonHelpers

data SortBy = Age | Name
instance FromHttpApiData SortBy where
  parseQueryParam text = case text of
    "age"  -> return Age
    "Age"  -> return Age
    "name" -> return Name
    "Name" -> return Name
    _ -> fail "Invalid SortBy param"

data User = User {
  user_id :: Integer
, user_name :: T.Text
, user_age :: Int
, user_email :: T.Text
} deriving (Eq, Show)
$(deriveJSON defaultOptions { fieldLabelModifier = dropPrefix_ } ''User)

newtype SingleUser = SingleUser { user :: User } deriving (Eq, Show)
$(deriveJSON defaultOptions ''SingleUser)

newtype ManyUsers = ManyUsers { users :: [User] } deriving (Eq, Show)
$(deriveJSON defaultOptions ''ManyUsers)

data NewUserInput = NewUserInput {
  input_name :: T.Text
, input_age :: Int
, input_email :: T.Text
} deriving (Eq, Show)
$(deriveJSON defaultOptions { fieldLabelModifier = dropPrefix_ } ''NewUserInput)
