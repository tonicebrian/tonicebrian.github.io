Página personal de Toni Cebrián
===============================

Muchos de los posts son documentos de Literate Programming que pueden ser
ejecutados por el intérprete de Haskell.

Para hacerlo, ejecutar el comando

```
ghci -pgmL spp.py -x lhs <fichero>.rst
````

Tanto el script como la forma de ejecutarlo has sido inspirados por [este blog post](http://blog.incubaid.com/2011/10/17/literate-programming-using-sphinx-and-haskell/). 


How to generate the site
========================

Execute:

```
stack build
stack exec site build
```



