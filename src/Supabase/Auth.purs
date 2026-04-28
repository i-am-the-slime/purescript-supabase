module Supabase.Auth
  ( module Supabase.Auth.Types
  , FunctionResponse
  , SignInWithOAuthOptions
  , channel
  , exchangeCodeForSession
  , functionsSetAuth
  , getChannels
  , getSession
  , getUser
  , invoke
  , onAuthStateChange
  , reauthenticate
  , refreshSession
  , removeAllChannels
  , removeChannel
  , resetPasswordForEmail
  , setSession
  , signInAnonymously
  , signInWithEmail
  , signInWithIdToken
  , signInWithOAuth
  , signInWithPhone
  , signInWithSSO
  , signOut
  , signUpWithEmail
  , signUpWithPhone
  , sendOtpToEmail
  , sendOtpToPhone
  , updateUser
  , verifyEmailOtp
  , verifyPhoneOtp
  ) where

import Prelude

import Control.Promise (Promise)
import Control.Promise as Promise
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, mkEffectFn1, runEffectFn1, runEffectFn2, runEffectFn3)
import Foreign (Foreign)
import Yoga.JSON (class ReadForeign, class WriteForeign, write)
import Data.Newtype (un)
import Prim.Row (class Union)
import Supabase.Auth.Types (AccessToken(..), AuthCode(..), AuthError, AuthResponse, AuthResult, IdToken(..), OAuthProvider(..), OTPToken(..), OTPType, RefreshToken(..), SSODomain(..), Session, User, UserEmail(..), UserId, UserPassword(..), UserPhone(..), otpTypeToString)
import Supabase.Types (Channel, ChannelName(..), Client, FunctionName(..))
import Supabase.Util as Util

-- Internal response conversion

type InternalAuthResult =
  { user :: Nullable User
  , session :: Nullable Session
  }

type InternalAuthResponse =
  { data :: InternalAuthResult
  , error :: Nullable AuthError
  }

convertResponse :: InternalAuthResponse -> AuthResponse
convertResponse { data: d, error: err } =
  { data: { user: Nullable.toMaybe d.user, session: Nullable.toMaybe d.session }
  , error: Nullable.toMaybe err
  }

-- signUp

foreign import signUpImpl :: EffectFn2 Client Foreign (Promise InternalAuthResponse)

signUpWithEmail :: { email :: UserEmail, password :: UserPassword } -> Client -> Aff AuthResponse
signUpWithEmail { email: UserEmail email, password: UserPassword password } client =
  runEffectFn2 signUpImpl client (write { email, password }) # Promise.toAffE <#> convertResponse

signUpWithPhone :: { phone :: UserPhone, password :: UserPassword } -> Client -> Aff AuthResponse
signUpWithPhone { phone: UserPhone phone, password: UserPassword password } client =
  runEffectFn2 signUpImpl client (write { phone, password }) # Promise.toAffE <#> convertResponse

-- signInWithPassword

foreign import signInWithPasswordImpl :: EffectFn2 Client Foreign (Promise InternalAuthResponse)

signInWithEmail :: { email :: UserEmail, password :: UserPassword } -> Client -> Aff AuthResponse
signInWithEmail { email: UserEmail email, password: UserPassword password } client =
  runEffectFn2 signInWithPasswordImpl client (write { email, password }) # Promise.toAffE <#> convertResponse

signInWithPhone :: { phone :: UserPhone, password :: UserPassword } -> Client -> Aff AuthResponse
signInWithPhone { phone: UserPhone phone, password: UserPassword password } client =
  runEffectFn2 signInWithPasswordImpl client (write { phone, password }) # Promise.toAffE <#> convertResponse

-- signInWithOtp

foreign import signInWithOtpImpl :: EffectFn2 Client Foreign (Promise InternalAuthResponse)

sendOtpToEmail :: { email :: UserEmail } -> Client -> Aff AuthResponse
sendOtpToEmail { email: UserEmail email } client =
  runEffectFn2 signInWithOtpImpl client (write { email }) # Promise.toAffE <#> convertResponse

sendOtpToPhone :: { phone :: UserPhone } -> Client -> Aff AuthResponse
sendOtpToPhone { phone: UserPhone phone } client =
  runEffectFn2 signInWithOtpImpl client (write { phone }) # Promise.toAffE <#> convertResponse

-- verifyOtp

foreign import verifyOtpImpl :: EffectFn2 Client Foreign (Promise InternalAuthResponse)

verifyEmailOtp :: { email :: UserEmail, token :: OTPToken, "type" :: OTPType } -> Client -> Aff AuthResponse
verifyEmailOtp { email: UserEmail email, token: OTPToken token, "type": typ } client =
  runEffectFn2 verifyOtpImpl client (write { email, token, "type": otpTypeToString typ }) # Promise.toAffE <#> convertResponse

verifyPhoneOtp :: { phone :: UserPhone, token :: OTPToken, "type" :: OTPType } -> Client -> Aff AuthResponse
verifyPhoneOtp { phone: UserPhone phone, token: OTPToken token, "type": typ } client =
  runEffectFn2 verifyOtpImpl client (write { phone, token, "type": otpTypeToString typ }) # Promise.toAffE <#> convertResponse

-- signInWithOAuth

type SignInWithOAuthOptions =
  ( provider :: OAuthProvider
  , options :: { redirectTo :: String, scopes :: String, queryParams :: Foreign }
  )

foreign import signInWithOAuthImpl :: EffectFn2 Client Foreign (Promise { data :: { provider :: String, url :: Nullable String }, error :: Nullable AuthError })

signInWithOAuth :: forall opts thru. Union opts thru SignInWithOAuthOptions => WriteForeign { | opts } => { | opts } -> Client -> Aff { data :: { provider :: OAuthProvider, url :: Maybe String }, error :: Maybe AuthError }
signInWithOAuth opts client = runEffectFn2 signInWithOAuthImpl client (write opts) # Promise.toAffE <#> convert
  where
  convert { data: d, error: err } =
    { data: { provider: OAuthProvider d.provider, url: Nullable.toMaybe d.url }
    , error: Nullable.toMaybe err
    }

-- signInWithIdToken

foreign import signInWithIdTokenImpl :: forall opts. EffectFn2 Client { | opts } (Promise InternalAuthResponse)

signInWithIdToken :: { provider :: OAuthProvider, token :: IdToken } -> Client -> Aff AuthResponse
signInWithIdToken { provider: OAuthProvider provider, token: IdToken token } client =
  runEffectFn2 signInWithIdTokenImpl client { provider, token } # Promise.toAffE <#> convertResponse

-- signInWithSSO

foreign import signInWithSSOImpl :: forall opts. EffectFn2 Client { | opts } (Promise { data :: { url :: Nullable String }, error :: Nullable AuthError })

signInWithSSO :: { domain :: SSODomain } -> Client -> Aff { data :: { url :: Maybe String }, error :: Maybe AuthError }
signInWithSSO { domain: SSODomain domain } client = runEffectFn2 signInWithSSOImpl client { domain } # Promise.toAffE <#> convert
  where
  convert { data: d, error: err } =
    { data: { url: Nullable.toMaybe d.url }
    , error: Nullable.toMaybe err
    }

-- signInAnonymously

foreign import signInAnonymouslyImpl :: EffectFn1 Client (Promise InternalAuthResponse)

signInAnonymously :: Client -> Aff AuthResponse
signInAnonymously client = runEffectFn1 signInAnonymouslyImpl client # Promise.toAffE <#> convertResponse

-- signOut

foreign import signOutImpl :: EffectFn1 Client (Promise { error :: Nullable AuthError })

signOut :: Client -> Aff { error :: Maybe AuthError }
signOut client = runEffectFn1 signOutImpl client # Promise.toAffE <#> \r -> { error: Nullable.toMaybe r.error }

-- updateUser

foreign import updateUserImpl :: EffectFn2 Client Foreign (Promise InternalAuthResponse)

updateUser :: forall r. WriteForeign { | r } => { | r } -> Client -> Aff AuthResponse
updateUser attrs client = runEffectFn2 updateUserImpl client (write attrs) # Promise.toAffE <#> convertResponse

-- resetPasswordForEmail

foreign import resetPasswordForEmailImpl :: EffectFn2 Client String (Promise { data :: {}, error :: Nullable AuthError })

resetPasswordForEmail :: UserEmail -> Client -> Aff { error :: Maybe AuthError }
resetPasswordForEmail (UserEmail email) client = runEffectFn2 resetPasswordForEmailImpl client email # Promise.toAffE <#> \r -> { error: Nullable.toMaybe r.error }

-- getSession

foreign import getSessionImpl :: EffectFn1 Client (Promise { data :: { session :: Nullable Session }, error :: Nullable AuthError })

getSession :: Client -> Aff { data :: { session :: Maybe Session }, error :: Maybe AuthError }
getSession client = runEffectFn1 getSessionImpl client # Promise.toAffE <#> convert
  where
  convert { data: d, error: err } =
    { data: { session: Nullable.toMaybe d.session }
    , error: Nullable.toMaybe err
    }

-- getUser

foreign import getUserImpl :: EffectFn1 Client (Promise { data :: { user :: Nullable User }, error :: Nullable AuthError })

getUser :: Client -> Aff { data :: { user :: Maybe User }, error :: Maybe AuthError }
getUser client = runEffectFn1 getUserImpl client # Promise.toAffE <#> convert
  where
  convert { data: d, error: err } =
    { data: { user: Nullable.toMaybe d.user }
    , error: Nullable.toMaybe err
    }

-- refreshSession

foreign import refreshSessionImpl :: EffectFn1 Client (Promise InternalAuthResponse)

refreshSession :: Client -> Aff AuthResponse
refreshSession client = runEffectFn1 refreshSessionImpl client # Promise.toAffE <#> convertResponse

-- setSession

foreign import setSessionImpl :: EffectFn2 Client { access_token :: String, refresh_token :: String } (Promise InternalAuthResponse)

setSession :: { access_token :: AccessToken, refresh_token :: RefreshToken } -> Client -> Aff AuthResponse
setSession { access_token: AccessToken at, refresh_token: RefreshToken rt } client =
  runEffectFn2 setSessionImpl client { access_token: at, refresh_token: rt } # Promise.toAffE <#> convertResponse

-- exchangeCodeForSession

foreign import exchangeCodeForSessionImpl :: EffectFn2 Client String (Promise InternalAuthResponse)

exchangeCodeForSession :: AuthCode -> Client -> Aff AuthResponse
exchangeCodeForSession (AuthCode code) client = runEffectFn2 exchangeCodeForSessionImpl client code # Promise.toAffE <#> convertResponse

-- reauthenticate

foreign import reauthenticateImpl :: EffectFn1 Client (Promise { data :: {}, error :: Nullable AuthError })

reauthenticate :: Client -> Aff { error :: Maybe AuthError }
reauthenticate client = runEffectFn1 reauthenticateImpl client # Promise.toAffE <#> \r -> { error: Nullable.toMaybe r.error }

-- onAuthStateChange

foreign import onAuthStateChangeImpl :: EffectFn2 Client (EffectFn1 (Nullable Session) Unit) { data :: { subscription :: { id :: String, unsubscribe :: Effect Unit } } }

onAuthStateChange :: (Maybe Session -> Effect Unit) -> Client -> Effect { data :: { subscription :: { id :: String, unsubscribe :: Effect Unit } } }
onAuthStateChange handler client = runEffectFn2 onAuthStateChangeImpl client (mkEffectFn1 (Nullable.toMaybe >>> handler))

-- invoke (edge functions)

type InternalFunctionResponse d = { "data" :: Nullable d, error :: Nullable { message :: String } }
type FunctionResponse d = { "data" :: Maybe d, error :: Maybe { message :: String } }

foreign import invokeImpl :: EffectFn3 Client String { body :: Foreign, headers :: Foreign } (Promise (InternalFunctionResponse Foreign))

invoke :: forall t body headers. ReadForeign t => WriteForeign body => WriteForeign headers => FunctionName -> body -> headers -> Client -> Aff (FunctionResponse t)
invoke fn body headers client = runEffectFn3 invokeImpl client (un FunctionName fn) { body: write body, headers: write headers } # Promise.toAffE >>= convert
  where
  convert { "data": d, error: err } = do
    parsed <- case Nullable.toMaybe d of
      Nothing -> pure Nothing
      Just f -> Util.fromJSON f <#> Just
    pure { "data": parsed, error: Nullable.toMaybe err }

-- functionsSetAuth

foreign import functionsSetAuthImpl :: EffectFn2 Client String Unit

functionsSetAuth :: AccessToken -> Client -> Effect Unit
functionsSetAuth (AccessToken token) client = runEffectFn2 functionsSetAuthImpl client token

-- channel

foreign import channelImpl :: EffectFn2 String Client Channel

channel :: ChannelName -> Client -> Effect Channel
channel (ChannelName name) client = runEffectFn2 channelImpl name client

-- getChannels

foreign import getChannelsImpl :: EffectFn1 Client (Array Channel)

getChannels :: Client -> Effect (Array Channel)
getChannels = runEffectFn1 getChannelsImpl

-- removeChannel

foreign import removeChannelImpl :: EffectFn2 Client Channel Unit

removeChannel :: Channel -> Client -> Effect Unit
removeChannel ch client = runEffectFn2 removeChannelImpl client ch

-- removeAllChannels

foreign import removeAllChannelsImpl :: EffectFn1 Client Unit

removeAllChannels :: Client -> Effect Unit
removeAllChannels = runEffectFn1 removeAllChannelsImpl
