---
comments: true
date: 2010-03-07 21:52:35
layout: post
slug: dfa-libraries-in-haskell
title: DFA libraries in Haskell
wordpressid: 9
categories: Thesis
tags: automata,haskell
---

Since I'm planning to write all the software for my final Master's Thesis in Haskell, the first natural step is to look for libraries already implementing Probabilistic Discrete Finite Automata in Haskell. The probabilistic condition was too much constraining and I have been only able to find some implementations of simple DFA. Here are the ones I have found:



	
  * [Halex](http://www.di.uminho.pt/~jas/Research/HaLeX/HaLeX.html) is a library for manipulating regular languages. It's a library developed at the University of Minho that also serves as the base lexer for the [HaGLR](http://wiki.di.uminho.pt/twiki/bin/view/Research/PURe/PUReSoftware) (a generalized LR parser). It has the nice feature of generating Graphviz diagrams from the DFAs. It is distributed under the LPGL

	
  * In this [page](http://vorlon.case.edu/~lps/software/automata/) you can download the software implementation that is explained in this [paper](citeseer.ist.psu.edu/461156.html) (_A Collection of Functional Libraries for Theory of Computation)_. The software is distributed under the LPGL.

	
  * When browsing through the Haskell Wiki you can find the [regular expressions](http://www.haskell.org/haskellwiki/Regular_expressions#regex-dfa) implementations. But the implementation of reference for the DFAs seems that is embedded in a more complex library, the[ Compiler Toolkit for Haskell](http://www.cse.unsw.edu.au/~chak/haskell/ctk/).

	
  * A number of implementations written by Haskell enthusiasts and documented in their blogs like this [one](http://nickelcode.com/2009/11/08/using-a-haskell-dfa-type-to-match-strings/) and this [set](http://blogs.msdn.com/matt/archive/2008/06/01/writing-a-regular-expression-parser-in-haskell-part-1.aspx) of articles.


Given this quick research of the available possibilities, the final choice will be to use the implementation described in the paper _A Collection of Functional Libraries for Theory of Computation_ for the creation of a Probabilistic DFA library. Here are the reasons:



	
  * This is a LPGL library so I can use it without restrictions. I will try to get a clean code so I could contribute back.

	
  * The library seems that is focused on the DFA where other options are more focused on creating a good lexer to be included on a bigger piece of code like a parser or similar.

	
  * It is well documented and can help me to understand the underlying design decisions.

	
  * It is very small and I won't get lost in the subtleties of a bigger implementation. Since I am a novice Haskeller this is a plus.


