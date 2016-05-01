---
comments: true
date: 2011-12-28 18:00:03
layout: post
slug: csv-parser-in-c-with-boost-and-template-metaprogramming
title: CSV parser in C++ with Boost and Template Metaprogramming
wordpressid: 318
categories: Programming
tags: boost,c++,csv,templates
---

One common situation when analyzing big chunks of data is to parse big CSV files with a record structure on each line. That is, all lines conform to a fixed schema where each line represents a record and each record has several columns of different types. Your objective is to parse and fill a data structure like this

``` cpp
struct foo {
    int a;
    std::string b;
    double c;
};
```
for each record. All the information needed for such parsing is in this data structure so I wondered whether I could write a program when you pass that type information and the parsing is done automatically for you. This is my first attempt at getting a flexible and fast CSV parser in C++. It is hosted in [Github](https://github.com/tonicebrian/csv_iterator).


## Design


When parsing CSV files the common usage pattern is to iterate through each line and perform a given action on each record. No need for a big CSV container or something similar, so the best approach is to write a class that acts as an iterator. When derreferencing the iterator it will return the provided data structure filled with parsed data from the current line. 

An iterator is associated to a container but in this case, it will be constructed accepting an _std::istream_ representing the CSV file. By accepting this istream we will be able to parse strings using the _std::stringstream_ class, regular files, or compressed files using the [Boost Iostream library](http://www.boost.org/doc/libs/1_48_0/libs/iostreams/doc/index.html).

The iterator must have all the common operators for it to interoperate with the STL algorithms seamlessly. The empty constructor will mark the iterator's end-of-range position that coincides with the end of file. A typical use case will be to have some code like this:

``` cpp
#include <fstream>
#include <boost/tuple/tuple.hpp>
#include <csv_iterator.hpp>

using namespace boost::tuples;
typedef tuple<int,std::string,double> record;

void myFunc(const record& value){
    // Your code here
}

int main(int argc, const char *argv[])
{
    // Example of csv_iterator usage
    std::ifstream in("myCsvFile.csv");
    csv::iterator<record> it(in);

    // Use the iterator in your algorithms.
    std::for_each(it, csv::iterator<record>(), myFunc);

    return 0;
}
```
for parsing CSV files like this:
``` bash
1,hola,3.14
2,adios,2.71
```



## Implementation


For obtaining the values on each line, the library uses the [Boost Tokenizer library](http://www.boost.org/doc/libs/1_48_0/libs/tokenizer/index.html). From a string you create a tokenizer that splits the input string by the character delimiter that by default is the comma. It also takes care of escaping characters. Accessing the different tokens is granted by the tokenizer by providing a token iterator.
``` cpp
using namespace boost;
typedef tokenizer<escaped_list_separator<char> > Tokens;
Tokens tokens(currentLine);
// Tokens can be accessed using tokens.begin() and tokens.end() iterators
```
Once we have the strings representing different values we have to parse and convert them into a type. Bad data format exceptions happen here and can be spotted earlier. For parsing using an unified approach the library uses the [Boost Lexical Cast Library](http://www.boost.org/doc/libs/1_48_0/doc/html/boost_lexical_cast.html). This library provides a uniform and portable interface for doing text conversions
``` cpp
int myInt = boost::lexical_cast<int>("5");
double myDouble = boost::lexical_cast<double>("3.14");
```
For the record data structure the library uses the [Boost Tuple Library](http://www.boost.org/doc/libs/1_48_0/libs/tuple/doc/tuple_users_guide.html) that provides a Plain "old" Data Structure for storing the record fields. Moreover this class provides some template infrastructure that helps in the metaprogramming trick that follows.



### Template metaprogamming


For our library the number of columns and the datatype is implicit in the record type. Our algorithm for parsing is basic, depending on the field type, parse the Nth string accordingly, and assign the result to the Nth field. Repeat for all the record fields. This [parametric polymorphism](http://en.wikipedia.org/wiki/Polymorphism_(computer_science)#Parametric_polymorphism) must be combined with the dynamic access of the string tokenization. The former can be obtained in C++ using [Template metaprogramming](http://en.wikipedia.org/wiki/Template_metaprogramming). The code that makes the trick is this one
``` cpp
template<class Tuple, int N >
    struct helper {
        static void fill(Tuple& tuple, strIt& it, strIt& end){
            using namespace boost::tuples;
            typedef typename element<length<Tuple>::value-N-1,Tuple>::type value_type;
            checkIteratorRange(it,end);
            get<length<Tuple>::value-N-1>(tuple) = boost::lexical_cast<value_type>(it->c_str());
            ++it;
            helper<Tuple,N-1>::fill(tuple,it,end);
        }
    };

template<class Tuple>
    struct helper<Tuple, 0> {
        static void fill(Tuple& tuple, strIt& it, strIt& end){
            using namespace boost::tuples;
            typedef typename boost::tuples::element<length<Tuple>::value-1,Tuple>::type value_type;
            checkIteratorRange(it,end);
            boost::tuples::get<length<Tuple>::value-1>(tuple) = boost::lexical_cast<value_type>(it->c_str());
            ++it;
        };
    };

template<class Tuple>
    struct filler {
       static void fill(Tuple& tuple, strIt&& it,strIt&& end){
            checkIteratorRange(it,end);
            helper<Tuple, boost::tuples::length<Tuple>::value-1>::fill(tuple,it,end);
        }
    };
```
Yes, C++ syntax sucks!! But basically what we are doing here is a common pattern of functional programming, [tail recursion](http://en.wikipedia.org/wiki/Tail_call). We define structures that contain static functions. The **filler** structure just initializes the recursive call by instantiating an instance of the **helper** paremeterized structure setting the length recursion to the number of fields in the tuple. This structure has to be specialized for the 0 value in order for the recursion to stop. All this functionality is done behind the curtain by the compiler (compilation time increases when using template metaprogramming) but the generated code will be something very similar to this pseudocode:
``` cpp
boost::tuples::get<0>(tuple) = (casting_here)*it; 
++it;
boost::tuples::get<1>(tuple) = (casting_here)*it; 
++it;
boost::tuples::get<2>(tuple) = (casting_here)*it; 
++it;
```
almost identical to the code we would have written by hand. The compiler is the one who knows how many fields our structure has at compile time and generates as many efficient instructions as needed.



## Conclusion


I wanted to stretch my programming muscles by coding a generic, flexible and fast CSV parser in C++ using template metaprogramming. The generic and flexible parts of the task have been accomplished but not the performance objectives. Although the library is fast enough for most tasks, it isn't in a scenario of Big Data parsing big files. The tokenizer iterator is incurring a performance penalty each time I try to derreference it, since it creates and allocates memory for a _std::string_ each time we invoke _*it_. This memory allocation is a performance drain doing useless work because we need this information only for parsing and getting a value, but the string is discarded thereafter. It would be better to perform an in-place parsing using the string allocated when reading the lines of the file. To that end it will be enlightening in the future to try this same exercise with more performant string libraries like the [C++ String Toolkit](http://www.partow.net/programming/strtk/index.html) and see the differences in performance.
