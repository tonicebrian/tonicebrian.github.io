---
comments: true
date: 2020-12-15 19:48:46
layout: post
slug: haskell
title: Creating eDSLs in Haskell using the Tagless Final approach
categories: Programming
tags: haskell, eDSL
---

# Introduction

After watching this video, I've bitten the bullet and I'm down the rabbit hole learning about [Free Monads and Tagless final](https://softwaremill.com/free-tagless-compared-how-not-to-commit-to-monad-too-early/) 
in order to  learn how to create eDSLs in Haskell.

<iframe width="560" height="315" src="https://www.youtube.com/embed/0aBWXqiuKR4" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

Although following the video is of moderate complexity, actually learning to apply those concepts is more difficult. So
I decided to replicate those steps as a kata exercise in order to internalize what was exposed there.

The author has a repo with all the things lined up in a final stage at [Github](https://github.com/zainab-ali/domainion) but the code
there is a bit different from what is being explained in the video, for instance the `ResourceSYM` doesn't exist in the final version,
so that was another reason for the kata.

This post was written in markdown and you need to install [markdown-unlit](https://github.com/sol/markdown-unlit) to tangle the code into the GHCI interpreter. The original markdown is in the repo associated to these github pages.

```bash
$ stack exec --package lens --package mtl -- ghci -x lhs -pgmL markdown-unlit dominion.md
```

# The problem

At [1:40](https://youtu.be/0aBWXqiuKR4?t=100) she exposes that using a card in a modern cards game involves just following a
set of instructions that change the game state. You read what's in the card and the game changes somehow. So as every programmer wants
to do, she creates in the video a language describing cards in the game [Dominion](https://boardgamegeek.com/boardgame/36218/dominion).

Let's start by defining some language pragmas and importing libraries.


```haskell
{-# LANGUAGE TemplateHaskell #-}
-- Required for deriving lenses
{-# LANGUAGE DeriveGeneric #-}
-- Required for constructing newtypes
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
-- We want to use forall quantification
-- Required for using forall quantification in Int
{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE RebindableSyntax #-}

module Dominion where

import Control.Lens
import Control.Monad.State hiding (modify)
import qualified Control.Monad.State as St
import Control.Monad.Trans.State.Lazy (StateT(..))
import Control.Newtype.Generics (pack, unpack)
import GHC.Generics
import Prelude hiding ((+), (-))
import qualified Prelude as P
```

## Modeling the Festival Card

![Festival Card](dominion-festival-card.png)

One approach to model effects in tha game is to use the `StateT` monad
transformer holding a state for the Game and the IO monad for rendering and
taking input. This is fine but you'll face problems if you want to extend the
set of cards in the future and being back compatible with existing ones (ie. the
[expression problem](https://en.wikipedia.org/wiki/Expression_problem))

At [6:44](https://youtu.be/0aBWXqiuKR4?t=404) she introduces what would be the
Initial Encoding approach in [the original paper from Oleg
Kiselov](http://okmij.org/ftp/tagless-final/course/lecture.pdf), but then she
shows the problems you face when you try to extend the language with extra
constructs. She says that we can overcome this extension problem by using Fixed
Point encoding but she is going to turn into the Tagless encoding using Type classes. 

So into the language, we will need to represent integers and operations between them:

```haskell 
class IntSym repr where
    lit :: Int -> repr
    (+) :: repr -> repr -> repr
```

When we use this language we will have something like
 
```haskell
exp1 :: IntSym repr => repr
exp1 = (lit 1 + lit 2) + lit 3
```

Then if we want to extend the language to accomodate substraction we can add a new term to our language

```haskell
class MinusSym repr where
    (-) :: repr -> repr -> repr
```

And both languages compose nicely if we add the restrictions

```haskell
exp2 :: (IntSym repr, MinusSym repr) => repr
exp2 = (lit 1 - lit 2) + lit 3
```

Those `exp1` and `exp2` are just constructs in our language, they are just
expressions, but we are interested in evaluating those expressions in order to
produce a result. With the Tagless Final approach, creating such interpreter
involves coding an interpreter in the form of an instance of those type classes
for the final result we want to accomplish:

```haskell
instance IntSym Int where
    lit n = n
    (+) = (P.+)
    
instance MinusSym Int where
    (-) = (P.-)
    
eval :: Int -> Int
eval = id
```

Then if we run our interpreter against a expression of the language:

```
ghci> eval expr2
2
```

So getting back to the Festival card at the beginning, our `IntSym` language is
a model for Integers, so all those `+2` and `+1` elements of our card can be
expressed between integers but we still lack terms for `action`, `buy` and
`gold`. For that we will create our Resources language

```haskell
class ResourcesSym repr where
    action :: repr
    buy :: repr
    gold :: repr
```

with this we can create all the lines in the card:

``` haskell
plusTwoActions :: (IntSym repr, ResSym repr) => repr
plusTwoActions = action + lit 2
```

Ok, if we want to evaluate this we cannot use the evaluators we used for the
`IntSym` language because they don't make any sense for the `ResourceSym` terms.
Moreover we want to interpret this language in terms of the `StateT` that drives
our game so we need to create a different interpreter.

But before moving to how to create the new interpreter we need to still fix the
problem of how to make invalid states non representable [min
11:54](https://youtu.be/0aBWXqiuKR4?t=714) (like `action + action` that right
now are valid expressions). And as a remainder the invalidity is linked to the
semantics of the language, ie. the expression `lit 2 + lit 1` was a perfectly
valid expressions when the semantics was the algebra of integers, but is an
invalid expression when we think about how to change the state of a game. What
does `lit 1 + lit 2` mean in the context of chaning state of a card game?

All the sentences in the Festival card look like a *modification* of a
*resource* by a *function*. So in order to get valid expressions we will create
a language for such statements. The enforment will be done through types.

Let me create the game state that will help us run these examples (by no means this is 
a valid representation of the state of a game like Dominion):

``` haskell
data Game = Game {
    _actions :: Int
} deriving (Show)


makeLenses ''Game
```

For this particular example, the resources could be seen as addresses of some properties in the state of a Player. Seen in such way, for instance, we will have a definition like:

```haskell
newtype GameLens a = GameLens (Lens' Game a)

class ResourceSym repr where 
    action :: repr (GameLens Int)
```
We need to wrap the lens in a Newtype instance so we can use lenses in typeclasses. Also the pragma `GeneralizedNewtypeDeriving` needs to be included

This means that our `repr` will be a type contaning a `Lens'`. That lens will be a simple one that provides setters and getters from a `Game` type to a property of type `Int` (the action in this case)

So with this type we can now model in our language those sentences from the card that 
modify player's state:

``` haskell
class StatementSym repr where
  modify :: repr (GameLens Int)
            -> (repr Int -> repr Int)
            -> repr ()
```

When defining interpreter instances for the StateT monad transformer we have to write


``` haskell
instance IntSym (State Game Int) where
    lit i = pure i
    x + y = do 
      x_int <- x
      y_int <- y
      P.return (x_int P.+ y_int)
      
instance ResourceSym (State Game) where
  action = pure (GameLens actions)
  
instance StatementSym (State Game) where
  modify mlens f = do (GameLens lens) <- mlens
                      next <- f (use lens)
                      St.modify (set lens next)
```

With this we can create a new expression in this language of cards

``` haskell
plusTwoActions :: (
  ResourceSym repr,
  IntSym (repr Int),
  StatementSym repr) => repr ()
plusTwoActions = modify action (+ lit 2)

```

When we evaluate this language in the context of the `State Game` monad, we have a real `State Game` monad ready to being executed or unrolled. Let's see how to get that:

``` haskell
-- Our interpreter
eval :: State Game a -> State Game a
eval = id

initialGame :: Game
initialGame = Game { _actions = 0 }

modifiedGame = execState (eval plusTwoActions) initialGame
```

And you can check that `modifiedGame` is `Game { _actions = 2 }`.

## Conclusion

I was first exposed to the Tagless Final approach in the excellent series of posts [Real World Halogen](https://thomashoneyman.com/guides/real-world-halogen/). The author uses type classes to model
capabilities of the application (creating logs, writing to a DB) with the benefit that later the actual 
implementations (ie. the interpreters) can change at will. Another benefit is testing, you don't need mocking
libraries like in other programming languages, you just swap the intepreter by another one where effects are 
fully controlled.

Free monads and tagless final are kind of equivalent and interchangeable, you could even use them in different parts
of your program without any problem, but from what I've been reading people think that tagless final is superior (see for
instance [this talk](https://www.youtube.com/watch?v=1h11efA4k8E)). But at the same time I'm currently reading [Functional Design and Architecture](https://leanpub.com/functional-design-and-architecture) were free monads are the core of all designs and I've also
discovered [Polysemy](https://github.com/polysemy-research/polysemy#readme) that promises to remove all the bolierplate code
associated with Free Monads and get the benefits of having you eDSL in memory. 

So for now I will go for the Tagless Final approach although I'll keep an eye on Polysemy and Free Monads.
