{-
Welcome to a Spago project!
You can edit this file as you like.

Need help? See the following resources:
- Spago documentation: https://github.com/purescript/spago
- Dhall language tour: https://docs.dhall-lang.org/tutorials/Language-Tour.html

When creating a new Spago project, you can use
`spago init --no-comments` or `spago init -C`
to generate this file without the comments in this block.
-}
{ name = "my-project"
, dependencies =
  [ "aff"
  , "affjax"
  , "affjax-web"
  , "argonaut-core"
  , "arrays"
  , "codec"
  , "codec-argonaut"
  , "console"
  , "effect"
  , "either"
  , "foldable-traversable"
  , "foreign-object"
  , "halogen"
  , "halogen-store"
  , "http-methods"
  , "lists"
  , "maybe"
  , "partial"
  , "prelude"
  , "profunctor"
  , "routing"
  , "routing-duplex"
  , "safe-coerce"
  , "strings"
  , "transformers"
  , "tuples"
  , "uuid"
  , "web-html"
  , "web-storage"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
