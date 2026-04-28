module Supabase.Realtime
  ( RealtimeResponse(..)
  , on
  , presenceState
  , send
  , subscribe
  , teardown
  , track
  , unsubscribe
  , untrack
  ) where

import Prelude

import Control.Promise (Promise, toAffE)
import Data.Maybe (Maybe(..))
import Data.Time.Duration (Milliseconds)
import Effect (Effect)
import Effect.Aff (Aff, throwError)
import Effect.Exception (Error, error)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, EffectFn4, mkEffectFn1, mkEffectFn2, runEffectFn1, runEffectFn2, runEffectFn3, runEffectFn4)
import Foreign (Foreign)
import Data.Either (either)
import Yoga.JSON (class ReadForeign, class WriteForeign, write)
import Yoga.JSON as Yoga
import Supabase.Realtime.ListenType (RealtimeListenType)
import Supabase.Realtime.SubscribeStates (RealtimeSubscribeState(ChannelError))
import Supabase.Realtime.SubscribeStates (fromString) as SubscribeState
import Untagged.Union (UndefinedOr, uorToMaybe)
import Supabase.Types (Channel)

data RealtimeResponse = SendingOK | SendingTimedOut | SendingRateLimited

-- send

foreign import sendImpl :: EffectFn2 Foreign Channel (Promise String)

send :: forall i. WriteForeign { | i } => { | i } -> Channel -> Aff RealtimeResponse
send input channel = do
  res <- runEffectFn2 sendImpl (write input) channel # toAffE
  case res of
    "ok" -> pure SendingOK
    "timed out" -> pure SendingTimedOut
    "rate limited" -> pure SendingRateLimited
    _ -> throwError (error ("Supabase.Realtime.send: invalid response: " <> res))

-- on

foreign import onImpl :: EffectFn4 RealtimeListenType Foreign (EffectFn1 Foreign Unit) Channel Unit

on :: forall f cbi. WriteForeign f => ReadForeign cbi => RealtimeListenType -> f -> (cbi -> Effect Unit) -> Channel -> Effect Unit
on lt filter callback channel = runEffectFn4 onImpl lt (write filter) (mkEffectFn1 \raw -> Yoga.read raw # either (\_ -> pure unit) callback) channel

-- subscribe

foreign import subscribeImpl :: EffectFn3 (EffectFn2 String (UndefinedOr Error) Unit) Milliseconds Channel Unit

subscribe :: Milliseconds -> (RealtimeSubscribeState -> Maybe Error -> Effect Unit) -> Channel -> Effect Unit
subscribe timeout cb channel =
  runEffectFn3 subscribeImpl
    ( mkEffectFn2 \st err ->
        case SubscribeState.fromString st of
          Nothing ->
            cb ChannelError (Just (error ("Supabase.Realtime.subscribe: invalid subscribe state: " <> st)))
          Just ok ->
            cb ok (uorToMaybe err)
    )
    timeout
    channel

-- unsubscribe

foreign import unsubscribeImpl :: EffectFn1 Channel (Promise Unit)

unsubscribe :: Channel -> Aff Unit
unsubscribe channel = runEffectFn1 unsubscribeImpl channel # toAffE

-- teardown

foreign import teardownImpl :: EffectFn1 Channel (Promise Unit)

teardown :: Channel -> Aff Unit
teardown channel = runEffectFn1 teardownImpl channel # toAffE

-- track (presence)

foreign import trackImpl :: EffectFn2 Foreign Channel (Promise String)

track :: forall payload. WriteForeign { | payload } => { | payload } -> Channel -> Aff RealtimeResponse
track payload channel = do
  res <- runEffectFn2 trackImpl (write payload) channel # toAffE
  case res of
    "ok" -> pure SendingOK
    "timed out" -> pure SendingTimedOut
    "rate limited" -> pure SendingRateLimited
    _ -> throwError (error ("Supabase.Realtime.track: invalid response: " <> res))

-- untrack

foreign import untrackImpl :: EffectFn1 Channel (Promise String)

untrack :: Channel -> Aff RealtimeResponse
untrack channel = do
  res <- runEffectFn1 untrackImpl channel # toAffE
  case res of
    "ok" -> pure SendingOK
    "timed out" -> pure SendingTimedOut
    "rate limited" -> pure SendingRateLimited
    _ -> throwError (error ("Supabase.Realtime.untrack: invalid response: " <> res))

-- presenceState

foreign import presenceStateImpl :: EffectFn1 Channel Foreign

presenceState :: Channel -> Effect Foreign
presenceState = runEffectFn1 presenceStateImpl
