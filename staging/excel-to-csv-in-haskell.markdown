---
comments: true
date: 2021-01-24 11:27:00
layout: post
slug: haskell
title: Converting Excel files to CSV in Haskell
categories: Programming
tags: haskell, data science
---
# Converting Excel files to CSV in Haskell

When doing data analysis it is very common that the raw data is encoded into a bunch of Excel files.
It is then convenient to translate that into CSV because most of the tools in our toolkit have some 
kind of CSV interoperability that is lacking for the Excel files.

If you need to do this in Python you have convenience functions like

```python
import pandas as pd
df = pd.read_excel("data.xlsx")
df.to_csv("data.csv")
```
How is this done in Haskell?

Reading the XLSX will be done using the [xlsx](https://hackage.haskell.org/package/xlsx) library and transforming to CSV will be done 
with the [Cassava](https://hackage.haskell.org/package/cassava) library.

This file is a Literate Haskell so you need to install [unlit](https://hackage.haskell.org/package/unlit) and then go to the sources and run it with:

```bash
$ stack exec --package cassava --package xlsx -- ghci -x lhs -pgmL markdown-unlit excel-to-csv-in-haskell.markdown
```

First some imports and pragmas

```haskell
{-# LANGUAGE OverloadedStrings #-}
module Excel2CSV where

import Codec.Xlsx
import qualified Data.ByteString.Lazy.Char8 as L
import Control.Lens
import Data.Csv
import Data.Text
import Text.Show.ByteString as SB
```

```haskell
renderCellValue :: Maybe CellValue -> L.ByteString
renderCellValue (Just (CellText text)) = SB.show . Prelude.show $ text
renderCellValue (Just (CellDouble d)) = SB.show d
renderCellValue (Just (CellBool True)) = "1"
renderCellValue (Just (CellBool False)) = "0"
renderCellValue (Just _) = "UNDEFINED"
renderCellValue Nothing = ""
```

```haskell
worksheet2csv :: Worksheet -> [Record]
worksheet2csv = undefined 

xlsx2csv :: Xlsx -> [(Text, [Record])]
xlsx2csv xlsx = undefined
 ```

Then it is just a matter of stiching all together in a main function

```haskell
main :: IO ()
main = do
  bs <- L.readFile "xlsx2csv.xlsx"
  L.putStrLn "Hola"
```
