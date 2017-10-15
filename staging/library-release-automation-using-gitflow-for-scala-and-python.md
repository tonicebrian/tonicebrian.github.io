# The problem

As many data science teams out there, the stack we use is composed of Python for data analysis and Scala for everything else that goes to production. In our case that means that for shared infrastructure we keep multilingual versions of the same artifacts, being those constants and enums, message serialization and deserialization for our microservice infrastructure and some simple business rules.

At the same time we chose [Gitflow AVH](https://github.com/petervanderdoes/gitflow-avh) for managing our development cycle. That means that we work on features on their own branch, that once reviewed get merged into branch `develop` (the pre-release branch) and from time to time we merge into the `master` branch in order to create a release. As a final note, we use Jenkins for our Continuous Integration system and Nexus for proxying and storing the binaries we create.

So all said, we look for a procedure for automate our release process satisfying:
- It must be language agnostic (or a least play nicely with Python and Scala). That rules out tool specific solutions like SBT plugin [sbt-release](https://github.com/sbt/sbt-release).
- It must integrate in our current release process we use with Gitflow.
- Jenkins must know how to build and release to Nexus all artifacts without human intervention.

# The procedure

Here I explain the procedure mostly inspired by the blog post [Painless release with SBT](http://blog.byjean.eu/2015/07/10/painless-release-with-sbt.html) and some [gitflow hooks](https://github.com/jaspernbrouwer/git-flow-hooks).
