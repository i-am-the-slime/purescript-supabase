module Test.Main where

import Prelude

import CompileFail.Spec (defaultConfig, goldenTests)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (runSpec)
import Test.Supabase.Codegen as Codegen

main :: Effect Unit
main = launchAff_ do
  compileFail <- goldenTests defaultConfig
  runSpec [ consoleReporter ] do
    Codegen.spec
    compileFail
