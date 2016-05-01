---
comments: true
date: 2012-02-23 10:59:19
layout: post
slug: parser-combinators-in-scala
title: Parser combinators in Scala
wordpressid: 361
categories: Programming
tags: parser,scala
---

Lately, I've been writing some [matrix factorization](http://research.yahoo.com/files/ieeecomputer.pdf) code for a video recommender system. I'm a big fan of Test Driven Development but it is a technique that is difficult for me to apply to the numerical or algorithmic domain. In order to make sure that the code I write is correct what I'm doing is the Oracle Test Pattern (I'm sure there is a correct name for this but I'm not able to find it right now). The idea is to have a reference implementation that solves the exact problem you are trying to solve. In my case, that reference implementation does not exists but I'm writing a straightforward unoptimized version of the script in Python using the Numpy libraries. That will be my ground truth when comparing results with the highly optimized parallel Scala version of the algorithm.


### The problem


So the problem is that I'm working interactively coding the algorithm in an iPython session and I'm getting results of this kind

``` python
In [4]: x
Out[4]:
matrix([[ 0.03893565, -0.35836827, -2.06492572,  1.49773613, -1.01988835,
         -0.20590096, -0.19658741],
        [ 0.43055155,  1.07532444,  0.89299596, -1.070371  , -0.24015718,
          0.04521229, -1.39209522],
        [-0.4482701 ,  0.15201451, -1.42824771,  1.13859559,  0.66432642,
          0.51184435,  0.52637519],
        [-0.26518471, -1.14331753, -1.15492029, -0.27501194,  1.73750282,
         -1.4118682 ,  0.14701005],
        [-1.6577536 , -0.0781593 , -0.01558478,  0.67277257, -0.07249647,
          0.70946581, -0.82349608]])
```

and I would like to just copy and paste this string and use it as the expected value in my Scala tests. That would involve to remove "matrix", all the "[" and "]", substitute them for their Array() equivalents and put an **F** at the end of each number denoting that it is a Float. Too much work.


### The solution


If there is an area where functional languages shine is in creating DSLs. More specifically creating an [internal DSL](http://martinfowler.com/bliki/InternalDslStyle.html) that looks more like an [external DSL](http://martinfowler.com/bliki/DomainSpecificLanguage.html). In Scala you can use the [Parser Combinator libraries](http://www.scala-lang.org/api/current/scala/util/parsing/combinator/Parsers.html) that are part of the Scala's core libraries. Such parser will be something like

``` scala
class PyMatrixParser extends JavaTokenParsers {
  def matrix:Parser[Array[Array[Float]]] = "matrix([" ~> repsep(row,",") <~ "])" ^^ (_.toArray)
  def row:Parser[Array[Float]] = "["~> repsep(floatingPointNumber,",") <~ "]" ^^ (_.map(_.toFloat).toArray)
}
```

using this parser is then just a matter of

``` scala
val parser = new PyMatrixParser
val scalaMatrix = parser.parseAll(parser.matrix, theStringMatrix).get
```

quite good result for just 2 lines of code defining the parser.

This is the quick overview for those not familiar with Scala's syntax



	
  * Every String that is found where a Scala Parser was meant to be, is automatically transformed into a constant parser that matches that exact string. So for instance,_"matrix(["_gets converted into a parser by one of the implicits in the parser combinators libraries.

	
  * _rep(row,",")_ takes two parsers as parameters and means that parser #1 will be repeated 0 or more times interleaved by parser #2

	
  * The parser combinators_ "~>"_ and _"<~"_ denote that the parser pointed by the arrow must be keep as the result of the parsing while the parser pointed by the tail must be discarded. This is helpful for combining two parser where one of them is just ornamental.

        
  * floatingPointNumber is a parser provided by the library that parses float point string representations

	
  * Each parser returns either the parsed string or a more complex Scala structure, like for instance, a list of strings in the case of _rep(parser1,parser2)_. Those results are sent to a parser transformator (the_ ^^_ operator) that works on the parser results and generates the true parsing result. In the example, first we create an array of Floats, and then an Array of Arrays of Floats that represent my matrix.


Really cool feature that has spared me a lot of grunt work by just writing two lines of code.
