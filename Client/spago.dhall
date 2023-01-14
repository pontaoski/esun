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
  , "argonaut"
  , "argonaut-core"
  , "arrays"
  , "bifunctors"
  , "codec"
  , "codec-argonaut"
  , "console"
  , "debug"
  , "effect"
  , "either"
  , "foldable-traversable"
  , "foreign-object"
  , "halogen"
  , "halogen-store"
  , "http-methods"
  , "integers"
  , "lists"
  , "maybe"
  , "numbers"
  , "partial"
  , "prelude"
  , "profunctor"
  , "routing"
  , "routing-duplex"
  , "safe-coerce"
  , "slug"
  , "spec"
  , "strings"
  , "transformers"
  , "tuples"
  , "uuid"
  , "web-dom"
  , "web-html"
  , "web-storage"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
