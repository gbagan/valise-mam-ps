{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name =
    "purescript"
, dependencies =
    [ "aff"
    , "arrays"
    , "effect"
    , "maybe"
    , "prelude"
    , "profunctor-lenses"
    , "run"
    , "strings"
    , "typelevel-prelude"
    ]
, packages =
    ./packages.dhall
, sources =
    [ "src/**/*.purs" ]
}
