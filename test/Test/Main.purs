module Test.Main where

import Prelude

import CompileFail.Spec (defaultConfig, goldenTests)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (runSpec)
import Test.Supabase.Codegen as Codegen
import Test.Supabase.Query as Query
import Test.Supabase.Auth as Auth
import Test.Supabase.SSR as SSR
import Test.Supabase.Stress as Stress
import Test.LSP as LSP

main :: Effect Unit
main = launchAff_ do
  compileFail <- goldenTests defaultConfig
  runSpec [ consoleReporter ] do
    Codegen.spec
    Query.spec
    Auth.spec
    SSR.spec
    Stress.spec
    LSP.spec
    compileFail
