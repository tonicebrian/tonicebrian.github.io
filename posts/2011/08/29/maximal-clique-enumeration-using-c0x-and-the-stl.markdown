---
comments: true
date: 2011-08-29 11:01:00
layout: post
slug: maximal-clique-enumeration-using-c0x-and-the-stl
title: Maximal clique enumeration using C++0x and the STL
wordpressid: 211
categories: Programming
tags: algorithm,c++,graph
---

Lately I've started to take a look at how parallelism is being done in a pure functional language like Haskell and their related technologies [Haskell in the Cloud](http://research.microsoft.com/en-us/um/people/simonpj/papers/parallel/remote.pdf) and [Data Parallel Haskell](http://www.haskell.org/haskellwiki/GHC/Data_Parallel_Haskell). As a proof of concept and in order to better learn those techniques, I want to parallelize the [Bron-Kerbosch algorithm](http://en.wikipedia.org/wiki/Bron%E2%80%93Kerbosch_algorithm) that returns the set of maximal [cliques](http://en.wikipedia.org/wiki/Clique_%28graph_theory%29) in a graph.The Bron-Kerbosch algorithm in pseudocode is something like this:

``` python
function bronKerbosch()
compsub = []
cand = V
not = []
cliqueEnumerate(compsub, cand, not)
```
and the _cliqueEnumerate_ function in pseudo-code:
``` python
function cliqueEnumerate(compsub, cand, not)
if cand = [] then 
    if not = [] then
        Output compsub
else
    fixp = The vertex in cand that is connected to the greatest number of other vertices in cand
    cur_v = fixp
    while cur_v != NULL do
        new_not = All vertices in not that are connected to cur_v
        new_cand = All vertices in cand that are connected to cur_v
        new_compsub = compsub + cur_v
        cliqueEnumerate(new_compsub, new_cand, new_not)
        not = not + cur_v
        cand = cand - cur_v
        if there is a vertex v in cand that is not connected to fixp then
           cur_v = v
        else
           cur_v = NULL
```

This pseudocode is from the paper, [_A scalable, parallel algorithm for maximal clique enumeration_](http://www.sciencedirect.com/science/article/pii/S0743731509000082)

  
I have written a first version of this algorithm in Haskell but, as a baseline and because I wanted to test the new features of the new C++0x standard, I've written this algorithm in C++ making extensive use of the STL and the lambdas. I forgot how verbose C++ is but the addition of the keyword **auto** and the lambdas has somehow alleviated it a little. 
``` cpp
void Graph::cliqueEnumerate(const vector<int>& compsub,
                     vector<int> cand,
                     vector<int> cnot,
                     vector<vector<int> >& result) const {

    // Function that answer whether the node is conected
    if(cand.empty()){
        if(cnot.empty()){
            // New clique found
            result.push_back(compsub);
        }
    } else{
        int fixp = findFixP(cand);
        int cur_v = fixp;

        while(cur_v != -1){
            vector<int> new_not;
            vector<int> new_cand;
            vector<int> new_compsub;

            // Auxiliar lambda function
            auto isConected =[cur_v,this](int x) {
                const vector<int>& edges = this->getEdges(x);
                return find(edges.begin(), edges.end(), cur_v) != edges.end();
            }; 

            // Compose new vector
            // Avoid performance bottlenecks by reserving memory before hand
            new_compsub.reserve(compsub.size()+1);
            new_not.reserve(cnot.size());
            new_cand.reserve(cand.size());
            copy_if(cnot.begin(),cnot.end(),back_inserter(new_not),isConected);
            copy_if(cand.begin(),cand.end(),back_inserter(new_cand),isConected);
            copy(compsub.begin(), compsub.end(), back_inserter(new_compsub));
            new_compsub.push_back(cur_v);

            // Recursive call
            cliqueEnumerate(new_compsub, new_cand, new_not, result);

            // Generate new cnot and cand for the loop
            cnot.push_back(cur_v);
            cand.erase(find(cand.begin(),cand.end(),cur_v));

            // Last check
            auto v = find_if(cand.begin(),
                             cand.end(), 
                             [fixp,this](int x) {
                                const vector<int>& edges = this->getEdges(x);
                                return find(edges.begin(), edges.end(), fixp) == edges.end();
                             });

            // Obtain new cur_v value
            if(v != cand.end()) cur_v = *v;
            else break;
        }
    }
}
```

and the helper function _findFixP_ is:
``` cpp
int Graph::findFixP(vector<int> cand) const {
    vector<int> connections;
    connections.resize(cand.size());

    // This is necessary for the set_intersection function
    sort(cand.begin(),cand.end());

    // Auxiliar lambda function
    auto intersection = [&cand, this](int x) -> int {
        const vector<int>& x_edges = this->getEdges(x);
        vector<int> intersection;

        set_intersection(x_edges.begin(), x_edges.end(),
                         cand.begin(), cand.end(),
                         back_inserter(intersection));
        return intersection.size();
    };

    // Create an auxiliar vector with the intersection sizes
    transform(cand.begin(),cand.end(),connections.begin(),intersection);

    // Find the maximum size and return the corresponding edge
    vector<int>::const_iterator it1, it2,itmax;
    int max = -1;
    itmax = cand.end();
    for(it1=cand.begin(),it2=connections.begin(); it1!=cand.end(); ++it1,++it2){
        if(max < *it2){
            max = *it2;
            itmax = it1;
        }
    }
    if(itmax == cand.end()) return -1;
    else return *itmax;
    }
}
```
For this function my first attempt was to write it using the _std::max_element_ function, but I was worried that since the function we pass isn't a transformation of the data but a comparison function (_less_), I was worried that on each comparison the set_intersection would be computed redundantly on each step.

There can be, for sure, room for improvement (any C++ guru in the audience?), but I'm pretty satisfied with the obtained implementation. It reads almost as the pseudocode. I think this is because I first wrote the Haskell version and the C++ has the functional flavor in it. Would I write first the C++ version and there would be for sure lots of nasty loops and array indexes.

