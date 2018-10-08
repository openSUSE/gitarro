# gitarro

![GUNDAM image](doc/gundam.jpg)
![GUNDAM image](doc/gundam.jpg)

[![Build Status Master branch](https://travis-ci.org/openSUSE/gitarro.svg?branch=master)](https://travis-ci.org/openSUSE/gitarro)
[![Gem Version](https://badge.fury.io/rb/gitarro.svg)](https://badge.fury.io/rb/gitarro)
![awesome-badge](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)

## Table of Content

- [Introduction](#introduction)
- [Install](#install)
- [Quickstart](#quickstart)
- [Basic concepts, installation, configuration, tests, syntax and a basic example](doc/BASICS.md)
- [Advanced usage](doc/ADVANCED.md)
- [How to contribute to gitarro development](doc/CONTRIBUTING.md)
- [Releasing gitarro](doc/RELEASING.md)

## Introduction

gitarro allow you to run tests on Git Hub [Pull Requests](https://help.github.com/articles/about-pull-requests/) (also known as PRs) using almost any script, language or binary and providing easy integration with other tools, and testing env. (such containers, cloud, VMS, etc.)

It can run on any system that is able to use ruby and [octokit](https://github.com/octokit/octokit.rb).

## Install

`gem install gitarro`

## Quickstart

1. Setup the netrc file
    ```shell
    echo "machine api.github.com login $GITHUB_USER password $GITUB_PWD_OR_TOKEN > /~.netrc"
    sudo chmod 0600 ~/.netrc
    ```

2. Create a test script for running against PRs

    ```shell
    echo "#! /bin/bash" > /tmp/tests.sh
    echo "exit 0" > /tmp/tests.sh
    chmod +x /tmp/tests.sh
    ```

3. Run gitarro against your GitHub project.

    ```shell
    YOUR_GITHUB_PROJECT="MalloZup/gitarro"
    gitarro.rb -r $YOUR_GITHUB_PROJECT -c "ruby-test" -t /tmp/tests.sh --https"
    ```

## Authors

- [Dario Maiocchi](https://github.com/MalloZup)

See also the list of [contributors](https://github.com/openSUSE/gitarro/graphs/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

### Extra

Gitarro is part of the curate list [Awesome Ruby](http://awesome-ruby.com)
