# gitarro

![GUNDAM image](doc/gundam.jpg)
![GUNDAM image](doc/gundam.jpg)

[![Build Status Master branch](https://travis-ci.org/openSUSE/gitarro.svg?branch=master)](https://travis-ci.org/openSUSE/gitarro)
[![Gem Version](https://badge.fury.io/rb/gitarro.svg)](https://badge.fury.io/rb/gitarro)

## Table of Content
- [Introduction](#introduction)
- [Install](#install)
- [Quickstart](#quickstart)
- [Basic concepts, installation, configuration, tests, syntax and a basic example](doc/BASICS.md)
- [Advanced usage](doc/ADVANCED.md)
- [How to contribute to gitarro development](doc/CONTRIBUTING.md)

gitarro allow you to run tests on Git Hub [Pull Requests](https://help.github.com/articles/about-pull-requests/) (also known as PRs) using almost any script, language or binary and providing easy integration with other tools, and testing env. (such containers, cloud, VMS, etc.)

It can run on any system that is able to use ruby and [octokit](https://github.com/octokit/octokit.rb).

## Install

``` gem install gitarro ```


## Quickstart


0. Setup the netrc file

```console
echo "machine api.github.com login $GITHUB_USER password $GITUB_PWD_OR_TOKEN > /~.netrc"
sudo chmod 0600 ~/.netrc
```
1. Create a test script for running against PRs
```console
echo "#! /bin/bash" > /tmp/tests.sh
echo "exit 0" > /tmp/tests.sh
chmod +x /tmp/tests.sh
```

2. Run gitarro against your GitHub project.

$YOUR_GITHUB_PROJECT=MalloZup/gitarro 

```console
gitarro.rb -r $YOUR_GITHUB_PROJECT -c "ruby-test" -t /tmp/tests.sh --https"
```

## Authors:

-  Dario Maiocchi 

See also the list of [contributors](https://github.com/openSUSE/gitarro/graphs/contributors) who participated in this project.

## License 

This project is licensed under the MIT License - see the LICENSE.md file for details
