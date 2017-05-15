---
comments: true
date: 2010-03-22 19:39:50
layout: post
slug: cmake-project-skeleton
title: CMake project skeleton
wordpressid: 27
categories: Programming
tags: c++,cmake,cppunit
---

When creating a new project from scratch, there are a lot of tasks that are repetitive and uninteresting. Creating makefiles, defining the project structure, etc... Usually you rely on your IDE to perform those tasks when you are on your own when creating CMake projects. I've created a simple project skeleton to speed up the setup of new C++ projects.

**Sample project**

You can access the project [here](https://bitbucket.org/tonicebrian/cmake_sample_project/overview). Just clone it and start the hacking.

**Directory structure**

Recently I have been working with Maven for Java development. I love the idea of Convention over Configuration ([CoC](http://en.wikipedia.org/wiki/Convention_over_configuration)). When coding, there are zillions of things you have to put in your head, why should you waste your precious brain cycles remembering in which folder are those configuration files your colleague created last week. You agree on an **arbitrary** convention and you stick to it. Suddenly some neurons are freed and you can use them to learn the next framework. When organizing my folders I have followed the Maven conventions, one big CMakeLists.txt file in the root directory, a src folder divided into main and test having each of them subfolders on a "per-technology" basis. Object files and executables go to a separated folder. In the figure you can see the directories structure.

![](CMakeProjectStructure.png)

**Unit testing**

In order to provide some functionality, the project creates a dynamic library with the functionality of a simple calculator. To test that this functionality works properly, a unit test has been created using the CppUnit framework. The project builds a test driver called UnitTester. This executable can be run without parameters and then it runs all the tests that were previously registered using the ﻿﻿﻿CPPUNIT_TEST_SUITE_REGISTRATION. If you want to run only a given set you specify it in the command line, useful for testing the test you are working on.

I don't use the CTest functionality in this project and so, the _make test _command does not work. I did this because I preferred to have an executable in the root binary folder instead of buried in the folder structure. Some situations like running Valgrind to check for memory leaks or controlling the exact location of the executable compensate the change.

**Packaging**

In the _cmake_ folder there are two scripts for defining the packaging. You can create a RPM or a DEB only by (un)commenting the corresponding lines in the root CMakeLists.txt.

**Future development**

I plan to continue updating this project skeleton in the future. Some issues that I will surely improve will be:



	
  * Find a satisfying solution for running the tests using the CTest philosophy.

	
  * Include the code that finds common libraries like Boost **Done! 2010-05-27**

	
  * Given that CMake is a crossplatform build environment, check that this project can run seamlessly in Windows or Mac, currently only tested in Linux.


