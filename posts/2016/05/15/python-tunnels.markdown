---
comments: true
date: 2016-05-15 19:48:46
layout: post
slug: python
title: Python tunneling
categories: Data Science
tags: tools, python
---

# How to create ssh tunnels in Python

Recently I've been doing a bit of data analysis on the production servers using
the [Jupyter notebook](http://jupyter.org/) from my laptop. This is convenient
since I have all the tools and libraries installed in my laptop for creating
interesting notebooks. But data is still missing when running the notebook since
the interesting data resides in the production machines. In the past I created
tunnels using command line `ssh -L` but this broke the flow when running
notebooks and figuring later that the tunnel wasn't setup or it was accessing
the wrong database because and old sesssion was still running. So the best
alternative is to have the tunnel creation as part of the iPython notebook. I
researched a bit and this are the recipes I found for creating tunnels with
Python.

## Creating a tunnel to a remote machine

This is the simplest tunnel. You want to access a remote machine and perform a
grep on some Apache logs or download a file that was in a remote folder. For
this you need to install
[paramiko](https://pypi.python.org/pypi/paramiko) and the required development libraries:

```
sudo apt-get install libssl-dev
pip install paramiko
```

All the instructions in this post assume that you have in your
`$HOME/.ssh/config` file the required info for connecting to a remote machine so
you don't risk of publishing usernames and passwords when pushing to a repo.

Here is the snippet that creates the connection:

```python
# Create a SSH connection
import paramiko
import os

ssh = paramiko.SSHClient()
ssh._policy = paramiko.WarningPolicy()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

ssh_config = paramiko.SSHConfig()
user_config_file = os.path.expanduser("~/.ssh/config")
if os.path.exists(user_config_file):
    with open(user_config_file) as f:
        ssh_config.parse(f)

cfg = {'hostname': THE_HOST_NAME_IN_CONFIG}

user_config = ssh_config.lookup(cfg['hostname'])
cfg["hostname"] = user_config["hostname"]
cfg["username"] = user_config["user"]
key=paramiko.RSAKey.from_private_key_file(privateKey)
cfg["pkey"] = key

if 'proxycommand' in user_config:
   cfg['sock'] = paramiko.ProxyCommand(user_config['proxycommand'])

ssh.connect(**cfg)
```

And then you can execute remote commands. For instance, grep the logs for a
given day and retrieve the hits to a given resource. This could be accomplished
doing:

```python
cmd = 'sudo grep "{}" /var/log/httpd/{} | grep myURL'.format(dayUnderStudy, access_log_file)
stdin, stdout, stderr = ssh.exec_command(cmd)
```

And then manipulating the `stdout` variable with pure Python code.

Once done, close the connection in your notebook.

```python
ssh.close()
```


## Creating a tunnel to a remote machine in order to access a third machine

This is the classical setup where you want to access databases that are only
visible from the machines in your cluster. This can be accomplished by Paramiko
itself but I found easier to setup the forwarding with a library that is itself
using Paramiko underneathi, [sshtunnel](https://pypi.python.org/pypi/sshtunnel).

```
pip install sshtunnel
```

So the setup is, we ssh to a machine A that has visibility access to a second
machine B. Usually what we want is to do is to map a port in B, for instance
MySQL port 3306, to a local free port in our host. We just create a server that
maps those ports

```python
from sshtunnel import SSHTunnelForwarder
import logging

server = SSHTunnelForwarder(
   (HOST_A, 22),
   ssh_username=USER_IN_A, 
   ssh_private_key="~/.ssh/id_rsa",
   remote_bind_address=(HOST_B, PORT_B),
   local_bind_address=('',MY_LOCAL_PORT),
   logger=logging.getLogger("devnull") 
   )

server.start()
```

If we were doing the tunneling for accessing a remote DB, using that remove
access can be done by:

```python
import MySQLdb
conn= MySQLdb.connect(host='127.0.0.1',
                  port=MY_LOCAL_PORT,
                  user=DB_USER, 
                  passwd=DB_PWD,
                  db=DATABASE)
```

And then closing all connections:

```python
conn.close()
server.stop()
```


