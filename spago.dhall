{ name = "purescript"
, dependencies =
  [ "aff"
  , "argonaut-codecs"
  , "argonaut-core"
  , "arrays"
  , "control"
  , "datetime"
  , "effect"
  , "either"
  , "foldable-traversable"
  , "gen"
  , "integers"
  , "lazy"
  , "lists"
  , "maybe"
  , "numbers"
  , "ordered-collections"
  , "pha"
  , "prelude"
  , "profunctor-lenses"
  , "random"
  , "record"
  , "strings"
  , "tailrec"
  , "transformers"
  , "tuples"
  , "unfoldable"
  , "unsafe-coerce"
  , "web-dom"
  , "web-events"
  , "web-html"
  , "web-pointerevents"
  , "web-storage"
  , "web-uievents"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}
