module Supabase.Auth.Types where

import Prelude

import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Foreign (Foreign)
import Supabase.UUID (UUID)

import Yoga.JSON (class ReadForeign, class WriteForeign)

newtype UserId = UserId UUID

derive instance Newtype UserId _
derive newtype instance Show UserId
derive newtype instance Eq UserId
derive newtype instance Ord UserId
derive newtype instance WriteForeign UserId
derive newtype instance ReadForeign UserId

newtype UserEmail = UserEmail String

derive instance Newtype UserEmail _
derive newtype instance Show UserEmail
derive newtype instance Eq UserEmail
derive newtype instance Ord UserEmail
derive newtype instance WriteForeign UserEmail
derive newtype instance ReadForeign UserEmail

newtype UserPhone = UserPhone String

derive instance Newtype UserPhone _
derive newtype instance Show UserPhone
derive newtype instance Eq UserPhone
derive newtype instance Ord UserPhone
derive newtype instance WriteForeign UserPhone
derive newtype instance ReadForeign UserPhone

newtype UserPassword = UserPassword String

derive instance Newtype UserPassword _
derive newtype instance Eq UserPassword
derive newtype instance WriteForeign UserPassword
derive newtype instance ReadForeign UserPassword

newtype OTPToken = OTPToken String

derive instance Newtype OTPToken _
derive newtype instance Eq OTPToken
derive newtype instance WriteForeign OTPToken
derive newtype instance ReadForeign OTPToken

data OTPType
  = OTPSignup
  | OTPMagiclink
  | OTPSMS
  | OTPPhoneChange
  | OTPEmailChange
  | OTPRecovery
  | OTPInvite
  | OTPEmail

derive instance Eq OTPType

otpTypeToString :: OTPType -> String
otpTypeToString = case _ of
  OTPSignup -> "signup"
  OTPMagiclink -> "magiclink"
  OTPSMS -> "sms"
  OTPPhoneChange -> "phone_change"
  OTPEmailChange -> "email_change"
  OTPRecovery -> "recovery"
  OTPInvite -> "invite"
  OTPEmail -> "email"

newtype Timestamp = Timestamp String

derive instance Newtype Timestamp _
derive newtype instance Show Timestamp
derive newtype instance Eq Timestamp
derive newtype instance Ord Timestamp
derive newtype instance WriteForeign Timestamp
derive newtype instance ReadForeign Timestamp

newtype IdToken = IdToken String

derive instance Newtype IdToken _
derive newtype instance Eq IdToken
derive newtype instance WriteForeign IdToken
derive newtype instance ReadForeign IdToken

newtype SSODomain = SSODomain String

derive instance Newtype SSODomain _
derive newtype instance Eq SSODomain
derive newtype instance Show SSODomain
derive newtype instance WriteForeign SSODomain
derive newtype instance ReadForeign SSODomain

newtype CookieName = CookieName String

derive instance Newtype CookieName _
derive newtype instance Eq CookieName
derive newtype instance Show CookieName
derive newtype instance WriteForeign CookieName
derive newtype instance ReadForeign CookieName

newtype CookieValue = CookieValue String

derive instance Newtype CookieValue _
derive newtype instance Eq CookieValue
derive newtype instance Show CookieValue
derive newtype instance WriteForeign CookieValue
derive newtype instance ReadForeign CookieValue

type User =
  { id :: UserId
  , email :: UserEmail
  , user_metadata :: Foreign
  , app_metadata :: Foreign
  , aud :: String
  , role :: String
  , created_at :: Timestamp
  , updated_at :: Timestamp
  }

newtype AccessToken = AccessToken String

derive instance Newtype AccessToken _
derive newtype instance Show AccessToken
derive newtype instance Eq AccessToken
derive newtype instance WriteForeign AccessToken
derive newtype instance ReadForeign AccessToken

newtype RefreshToken = RefreshToken String

derive instance Newtype RefreshToken _
derive newtype instance Show RefreshToken
derive newtype instance Eq RefreshToken
derive newtype instance WriteForeign RefreshToken
derive newtype instance ReadForeign RefreshToken

newtype OAuthProvider = OAuthProvider String

derive instance Newtype OAuthProvider _
derive newtype instance Show OAuthProvider
derive newtype instance Eq OAuthProvider
derive newtype instance WriteForeign OAuthProvider
derive newtype instance ReadForeign OAuthProvider

newtype AuthCode = AuthCode String

derive instance Newtype AuthCode _
derive newtype instance Eq AuthCode
derive newtype instance WriteForeign AuthCode
derive newtype instance ReadForeign AuthCode

type Session =
  { access_token :: AccessToken
  , token_type :: String
  , expires_in :: Int
  , expires_at :: Int
  , refresh_token :: RefreshToken
  , user :: User
  }

type AuthResult =
  { user :: Maybe User
  , session :: Maybe Session
  }

type AuthResponse =
  { data :: AuthResult
  , error :: Maybe AuthError
  }

type AuthError =
  { message :: String
  , status :: Maybe Int
  }
