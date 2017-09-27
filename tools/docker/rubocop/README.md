# What is this?

A set of of images with gitarro and rubocop installed, so you can run static code tests on your GitHub repositories.

# Supported tags

- latest

# How to launch

First, decide if you want to check Pull Requests or you want to check branches.

## Pull Requests

If you want to check Pull Requests, use the following syntax:

```console
docker run --rm -e OPERATION='PR' -e gitarro_PARAMS='<gitarro_PARAMS>' -e GITHUB_USER='<GITHUB_USER>' -e GITHUB_PASSWORD='<GITHUB_PASSWORD_OR_PERSONAL_TOKEN>' rubocop:latest
```

* ```<gitarro_PARAMS>``` are all the parameters you need to use for gitarro (see documentation for more help)
* ```<GITHUB_USER>``` is a GitHub username, used to interact with GitHub API to update the Pull Request status
* ```<GITHUB_PASSWORD_OR_PERSONAK_TOKEN>``` is a GitHub password or Personal Token, used to interact with GitHub API to update the Pull Request status

Optionally you can specify a parameter ```-e TEST_SCRIPT='<source_code>'``` with the source code of the test script. Note that PWD for the script will ```/opt/gitarro/``` so keep this in mind along with the path you use for gitarro option ```-g``` if you use it.

As a tip, if you are using a shebang (such as ```#!/bin/bash```) and multiple lines, remember to add the corresponding escape secuences.

However, ideally, your test script should be at the same repository where your sources are, and you should just call it using gitarro. It will save you a lot of headaches.

**NOTE:** If you do not use ```--https``` at ```<gitarro_PARAMS>```, gitarro will use SSH to clone the repository, so make sure to read about ```SSH_PRIVATE_KEY``` below.

## Branches

If you want to check branches (or in theory any ref), use the following syntax:

```console
docker run --rm -e OPERATION=NON-PR -e GITHUB_REPO_URL='<URL_OF_GITHUB_REPO>' -e GIT_REF='<GIT_REF>' rubocop:latest
```

* ```<URL_OF_GITHUB_REPO>``` is the URL used to clone your repo. You can use HTTPS or SSH, but if you are using SSH make sure to read about ```SSH_PRIVATE_KEY``` below.
* ```<GIT_REF>``` is a Git reference (tag, branch, commit, HEAD...)

## Extra parameters

### Pass a private key

You specify a private SSH key (useful if you want to clone private repos) with:

```-e SSH_PRIVATE_KEY="<your_private_key>```

**NOTE:** The value must be the actual private key, not a path. If you want to use a real file use ```$(cat <path_to_file)```.

### Pass rubocop_todo.yml

As well as the content of a ```rubocop_todo.yml``` file that will overwrite the file at the local copy of the repository to be tested:

```-e RUBOCOP_TODO="<rubocop_todo_content>"```

**NOTE:** The value must be the actual content of a ```rubocop_todo.yml``` file, not a path. If you want to use a real file use ```$(cat <path_to_file)```.
