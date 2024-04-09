{-# LANGUAGE OverloadedStrings #-}
module Tests.Writers.Typst (tests) where

import Data.Text (unpack)
import Test.Tasty
import Test.Tasty.HUnit (HasCallStack)
import Tests.Helpers
import Text.Pandoc
import Text.Pandoc.Arbitrary ()
import Text.Pandoc.Builder

typstWithOpts :: (ToPandoc a) => WriterOptions -> a -> String
typstWithOpts opts = unpack . purely (writeTypst opts) . toPandoc

typst :: (ToPandoc a) => a -> String
typst = typstWithOpts def

{-
  "my test" =: X =?> Y

is shorthand for

  test html "my test" $ X =?> Y

which is in turn shorthand for

  test html "my test" (X,Y)
-}

infix 4 =:
(=:) :: (ToString a, ToPandoc a, HasCallStack)
     => String -> (a, String) -> TestTree
(=:) = test typst

toRow :: [Blocks] -> Row
toRow = Row nullAttr . map simpleCell

toHeaderRow :: [Blocks] -> [Row]
toHeaderRow l = [toRow l | not (null l)]


tests :: [TestTree]
tests =
  [ testGroup "typst properties"
    [ "span text" =:
     spanWith ("", [], [("typst:text:fill", "orange")]) "foo"
    =?> "#text(fill: orange)[foo]"
    , "table" =:
      let headers = []
          rows = []
      in tableWith ("", [], [("typst:fill", "blue")])
                    emptyCaption
                    []
                    (TableHead nullAttr $ toHeaderRow headers)
                    [TableBody nullAttr 0 [] $ map toRow rows]
                    (TableFoot nullAttr [])
    =?> unlines [ 
        "#figure("
      , "  align(center)[#table("
      , "    columns: 0,"
      , "    align: (),"
      , "    fill: blue,"
      , "  )]"
      , "  , kind: table"
      , "  )"
      ]
    , "table text" =:
      let headers = []
          rows = []
      in tableWith ("", [], [("typst:text:fill", "orange")])
                    emptyCaption
                    []
                    (TableHead nullAttr $ toHeaderRow headers)
                    [TableBody nullAttr 0 [] $ map toRow rows]
                    (TableFoot nullAttr [])
    =?> unlines [ 
        "#figure("
      , "  align(center)[#text(fill: orange)[#table("
      , "    columns: 0,"
      , "    align: (),"
      , "  )]]"
      , "  , kind: table"
      , "  )"
      ]
    , "table cell" =:
      let headers = []
          rows = [Row nullAttr [
              cellWith ("", [], [("typst:fill", "blue")]) AlignDefault (RowSpan 1) (ColSpan 1) $ para "Foo"
            , simpleCell $ para "Bar"
            ]]
      in table
                    emptyCaption
                    [(AlignDefault,ColWidthDefault),(AlignDefault,ColWidthDefault)]
                    (TableHead nullAttr $ toHeaderRow headers)
                    [TableBody nullAttr 0 [] rows]
                    (TableFoot nullAttr [])
    =?> unlines [ 
        "#figure("
      , "  align(center)[#table("
      , "    columns: 2,"
      , "    align: (auto,auto,),"
      , "    table.cell(fill: blue)[Foo"
      , ""
      , "    ], [Bar"
      , ""
      , "    ],"
      , "  )]"
      , "  , kind: table"
      , "  )"
      ]
    , "table cell text" =:
      let headers = []
          rows = [Row nullAttr [
              cellWith ("", [], [("typst:text:fill", "orange")]) AlignDefault (RowSpan 1) (ColSpan 1) $ para "Foo"
            , simpleCell $ para "Bar"
            ]]
      in table
                    emptyCaption
                    [(AlignDefault,ColWidthDefault),(AlignDefault,ColWidthDefault)]
                    (TableHead nullAttr $ toHeaderRow headers)
                    [TableBody nullAttr 0 [] rows]
                    (TableFoot nullAttr [])
    =?> unlines [ 
        "#figure("
      , "  align(center)[#table("
      , "    columns: 2,"
      , "    align: (auto,auto,),"
      , "    [#set text(fill: orange); Foo"
      , ""
      , "    ], [Bar"
      , ""
      , "    ],"
      , "  )]"
      , "  , kind: table"
      , "  )"
      ]
    ]
  ]