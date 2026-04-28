module Test.Supabase.Auth where

import Prelude

import Data.Array (length)
import Data.Maybe (Maybe(..), isJust, isNothing)
import Effect.Aff (finally)
import Effect.Class (liftEffect)
import Supabase (signUpWithEmail, signInWithEmail, signOut, getUser, getSession, updateUser, refreshSession, resetPasswordForEmail, signInAnonymously, verifyEmailOtp, setSession, reauthenticate, exchangeCodeForSession, onAuthStateChange, channel, getChannels, removeAllChannels)
import Supabase.Auth.Types (AccessToken(..), AuthCode(..), RefreshToken(..), UserEmail(..), UserPassword(..), UserId(..), OTPToken(..), OTPType(..))
import Supabase.Types (ChannelName(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Supabase.Helpers (mkClient, nowMs)

pw :: UserPassword
pw = UserPassword "password123456"

withUser :: String -> (UserEmail -> _ -> _) -> _
withUser prefix action = do
  client <- mkClient
  ts <- liftEffect nowMs
  let email = UserEmail (prefix <> show ts <> "@example.com")
  signUpRes <- client # signUpWithEmail { email, password: pw }
  finally (signOut client *> pure unit) (action email { client, signUpRes })

spec :: Spec Unit
spec = describe "Supabase.Auth" do

  describe "signUpWithEmail" do
    it "creates a user with id and session" do
      withUser "signup-" \_ { signUpRes } -> do
        signUpRes.error # isNothing # shouldEqual true
        signUpRes.data.user # isJust # shouldEqual true
        signUpRes.data.session # isJust # shouldEqual true
        (signUpRes.data.user <#> _.id) # isJust # shouldEqual true

  describe "signInWithEmail" do
    it "returns a session with tokens" do
      client <- mkClient
      ts <- liftEffect nowMs
      let email = UserEmail ("signin-" <> show ts <> "@example.com")
      _ <- client # signUpWithEmail { email, password: pw }
      _ <- signOut client
      res <- client # signInWithEmail { email, password: pw }
      res.error # isNothing # shouldEqual true
      res.data.session # isJust # shouldEqual true
      case res.data.session of
        Nothing -> pure unit
        Just s -> do
          s.access_token # (_ /= AccessToken "") # shouldEqual true
          s.refresh_token # (_ /= RefreshToken "") # shouldEqual true
          s.expires_in # (_ > 0) # shouldEqual true
      _ <- signOut client
      pure unit

  describe "signOut" do
    it "clears the session" do
      withUser "signout-" \_ { client } -> do
        _ <- signOut client
        res <- getSession client
        res.data.session # isNothing # shouldEqual true

  describe "getUser" do
    it "returns user with matching email" do
      withUser "getuser-" \email { client } -> do
        res <- getUser client
        res.error # isNothing # shouldEqual true
        (res.data.user <#> _.email) `shouldEqual` Just email

  describe "getSession" do
    it "returns session when signed in" do
      withUser "getsession-" \_ { client } -> do
        res <- getSession client
        res.error # isNothing # shouldEqual true
        res.data.session # isJust # shouldEqual true

    it "returns Nothing when not signed in" do
      client <- mkClient
      res <- getSession client
      res.data.session # isNothing # shouldEqual true

  describe "updateUser" do
    it "updates metadata and returns updated user" do
      withUser "update-" \_ { client } -> do
        res <- client # updateUser { data: { display_name: "Test User" } }
        res.error # isNothing # shouldEqual true
        res.data.user # isJust # shouldEqual true

  describe "refreshSession" do
    it "returns a new session" do
      withUser "refresh-" \_ { client } -> do
        res <- refreshSession client
        res.error # isNothing # shouldEqual true
        res.data.session # isJust # shouldEqual true

  describe "resetPasswordForEmail" do
    it "succeeds without error" do
      client <- mkClient
      ts <- liftEffect nowMs
      let email = UserEmail ("reset-" <> show ts <> "@example.com")
      _ <- client # signUpWithEmail { email, password: pw }
      _ <- signOut client
      res <- client # resetPasswordForEmail email
      res.error # isNothing # shouldEqual true

  describe "signInAnonymously" do
    it "creates an anonymous session" do
      client <- mkClient
      res <- signInAnonymously client
      res.error # isNothing # shouldEqual true
      res.data.session # isJust # shouldEqual true
      res.data.user # isJust # shouldEqual true
      _ <- signOut client
      pure unit

  describe "setSession" do
    it "restores session from tokens" do
      client <- mkClient
      ts <- liftEffect nowMs
      let email = UserEmail ("setsession-" <> show ts <> "@example.com")
      signUpRes <- client # signUpWithEmail { email, password: pw }
      case signUpRes.data.session of
        Nothing -> pure unit
        Just session -> do
          res <- client # setSession { access_token: session.access_token, refresh_token: session.refresh_token }
          res.error # isNothing # shouldEqual true
          res.data.session # isJust # shouldEqual true
          _ <- signOut client
          pure unit

  describe "verifyEmailOtp" do
    it "rejects invalid token" do
      client <- mkClient
      res <- client # verifyEmailOtp { email: UserEmail "nobody@example.com", token: OTPToken "000000", "type": OTPEmail }
      res.error # isJust # shouldEqual true

  describe "exchangeCodeForSession" do
    it "rejects invalid code" do
      client <- mkClient
      res <- client # exchangeCodeForSession (AuthCode "invalid-code")
      res.error # isJust # shouldEqual true

  describe "reauthenticate" do
    it "succeeds with active session" do
      withUser "reauth-" \_ { client } -> do
        res <- reauthenticate client
        res.error # isNothing # shouldEqual true

  describe "onAuthStateChange" do
    it "returns subscription with unsubscribe" do
      client <- mkClient
      sub <- client # onAuthStateChange (\_ -> pure unit) # liftEffect
      sub.data.subscription.id # (_ /= "") # shouldEqual true
      sub.data.subscription.unsubscribe # liftEffect

  describe "channel management" do
    it "creates and lists channels" do
      client <- mkClient
      _ <- client # channel (ChannelName "test-ch") # liftEffect
      channels <- getChannels client # liftEffect
      length channels # (_ > 0) # shouldEqual true
      removeAllChannels client # liftEffect
      channels2 <- getChannels client # liftEffect
      length channels2 `shouldEqual` 0

  describe "error cases" do
    it "signInWithEmail fails with wrong password" do
      client <- mkClient
      ts <- liftEffect nowMs
      let email = UserEmail ("err-wrongpw-" <> show ts <> "@example.com")
      _ <- client # signUpWithEmail { email, password: pw }
      _ <- signOut client
      res <- client # signInWithEmail { email, password: UserPassword "WRONG" }
      res.error # isJust # shouldEqual true
      res.data.session # isNothing # shouldEqual true
      _ <- signOut client
      pure unit

    it "signInWithEmail fails with nonexistent user" do
      client <- mkClient
      res <- client # signInWithEmail { email: UserEmail "nonexistent@example.com", password: UserPassword "whatever" }
      res.error # isJust # shouldEqual true

    it "getUser returns error when not signed in" do
      client <- mkClient
      res <- getUser client
      (res.data.user # isNothing) `shouldEqual` true

    it "updateUser fails when not signed in" do
      client <- mkClient
      res <- client # updateUser { data: { foo: "bar" } }
      res.error # isJust # shouldEqual true

    it "refreshSession fails when no session" do
      client <- mkClient
      res <- refreshSession client
      res.data.session # isNothing # shouldEqual true
