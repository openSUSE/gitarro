# gitarro

![GUNDAM image](doc/gundam.jpg)
![GUNDAM image](doc/gundam.jpg)

[![Build Status Master branch](https://travis-ci.org/openSUSE/gitarro.svg?branch=master)](https://travis-ci.org/openSUSE/gitarro)

## Introduction

gitarro allow you to run tests on Git Hub [Pull Requests](https://help.github.com/articles/about-pull-requests/) (also known as PRs) using almost any script, language or binary and providing easy integration with other tools, and testing env. (such containers, cloud, VMS, etc.)

It can run on any system that is able to use ruby and [octokit](https://github.com/octokit/octokit.rb).

## Install

``` gem install gitarro ```


## Quickstart


0. Create a fake test script that will run against your open Pull Request.

```console

echo "machine api.github.com login $GITHUB_USER password $GITUB_PWD_OR_TOKEN > /~.netrc"
sudo chmod 0600 ~/.netrc
echo "#! /bin/bash" > /tmp/tests.sh
echo "exit 0" > /tmp/tests.sh
chmod +x /tmp/tests.sh
```

1. Run gitarro against your GitHub project.

$YOUR_GITHUB_PROJECT=MalloZup/gitarro 

```console
gitarro.rb -r $YOUR_GITHUB_PROJECT -c "ruby-test" -g /tmp/ruby21 -t /tmp/tests.sh --https"
```

## Documentation

* [Basic concepts, installation, configuration, tests, syntax and a basic example](doc/BASICS.md)
* [Advanced usage](doc/ADVANCED.md)
* [Real life examples](doc/REAL_EXAMPLES.md)
* [How to contribute to gitarro development](doc/CONTRIBUTING.md)
