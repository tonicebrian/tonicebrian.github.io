# The problem

As many data science teams out there, the stack we use is composed of Python for
data analysis and Scala for everything else that goes to production. In our case
that means that for shared infrastructure we keep multilingual versions of the
same artifacts, being those constants and enums, message serialization and
deserialization for our microservice infrastructure and some simple business
rules.

At the same time we chose [Gitflow
AVH](https://github.com/petervanderdoes/gitflow-avh) for managing our
development cycle. That means that we work on features on their own branch, that
once reviewed get merged into branch `develop` (the pre-release branch) and from
time to time we merge into the `master` branch in order to create a release. As
a final note, we use Jenkins for our Continuous Integration system and Nexus for
proxying and storing the binaries we create.

So all said, we look for a procedure for automate our release process satisfying:
- It must be language agnostic (or a least play nicely with Python and Scala)
- It must integrate in our current release process we use with Gitflow.
- The CI system of your choice must know how to build and release to Nexus all
  artifacts without human intervention.
- Work mostly in a convention over configuration manner. It is OK to configure
  things at the beginning but after that everything should run without much
  intervention.

# The procedure

We will use Git flow as our development process if you are not familiar please
go check the great [git-flow
cheatsheet](https://danielkummer.github.io/git-flow-cheatsheet/). Just make sure
that you install the AVH version of Gitflow since that's the only that works
with the procedure explained here.

So the moment we adopt gitflow, new features are developed in their own branch
and when they are ready they are merged into `develop` branch (usually squashing
the merge and pointing in the commit message the issue that sparked the feature
creation). Develop thus is the Release Candidate branch and is accumulating
several futures that from time to time get merged into master. Merging into
master will be a regular merge because the idea is that new features pile up in
develop and from time to time we move them to a release. So since commits in
develop and master will be mostly the same, we need to mark when a new "batch"
was produced, i.e. tag commits in master with versions.

Those versions must follow [Semantic Versioning](https://semver.org/) using the
usual triple number schema. 

Here I explain the procedure mostly inspired by the blog post [Painless release
with SBT](http://blog.byjean.eu/2015/07/10/painless-release-with-sbt.html) and
some [gitflow hooks](https://github.com/jaspernbrouwer/git-flow-hooks).

