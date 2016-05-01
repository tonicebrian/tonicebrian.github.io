---
comments: true
date: 2010-07-13 21:14:59
layout: post
slug: distributed-version-control-system-with-dropbox-and-mercurial
title: Distributed Version Control System with Dropbox and Mercurial
wordpressid: 60
categories: Programming
tags: dropbox,mercurial
---

When developing software you should use a Version Control System like Subversion, Git or Mercurial. It will spare you some nasty nightmares and it can also add you the discipline of focused work if you use it in combination with TDD or other XP practices. I used Subversion for VCS but my personal working situation made SVN a poor choice.

My requisites for a truly distributed Version Control System can be summarized in the following list:



	
  * Be able to work I work with several computers (home, laptop, notebook, parents' computers, ...) and I want to be able to access the repository over the Internet. This can be solved using one of the existing public repositories like [Github](http://github.com/), [Bitbucket](http://bitbucket.org/) or [Sourceforge](http://sourceforge.net/).

	
  * I need a repository backed up in the cloud for preventing data loss.

	
  * I need to create private repositories.

	
  * I need to work with the VCS even when I have no Internet connection. This requisite discards classical VCS like [CVS](http://www.nongnu.org/cvs/) or [Subversion](http://subversion.apache.org/) and only allows newer ones like [Mercurial](http://mercurial.selenic.com/), [Git](http://git-scm.com/) or [Darcs](http://darcs.net/).


The solution I have found very satisfying is to create a repository in a folder controlled by [Dropbox](http://www.dropbox.com), treat this as the "main" repository and clone a working copy in a local workspace. After that, I can work off-line doing commits against my working copy and by means of the push and pull commands I synchronize each working copy on each of the different computers.

The only issue I have to take into account is to not push changes when I have no Internet connection and Dropbox can not synchronize to the cloud. If I would do that in two computers without connection I could incur on versioning conflicts that Dropbox could not resolve. This is not an issue because I can work locally as long as I want without any problem. Mercurial is able to track new commits and clone the local working copy just waiting for the moment when net connectivity is working again.

Check this [great tutorial](http://hginit.com/) of Mercurial written by Joel Spolsky in order to learn how to work with this Distributed Version Control System.

PD. If you have found this article interesting and you don't have a Dropbox account, please consider opening your account using [this referral](https://www.dropbox.com/referrals/NTUyNTE5MzA5), we'll both get extra space in our accounts ;)
