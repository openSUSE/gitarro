[Documentation index](../README.md#documentation)


# A basic example

Substitute this with your cred
GITHUB_USER="GRANDE_USER"
GITUB_PWD_OR_TOKEN="MYPASSWORD"

```console

echo "machine api.github.com login $GITHUB_USER password $GITUB_PWD_OR_TOKEN > /~.netrc"

echo "#! /bin/bash" > /tmp/tests.sh
chmod +x /tmp/tests.sh
gitarro.rb -r openSUSE/gitarro -c "ruby-test" -g /tmp/ruby21 -t /tmp/tests.sh --https"
```


# Basic concepts

gitarro runs a validation script, binary or command (-t or --test) against PRs of the GitHub repository you specify (-r or --repo) .

There are two basic ways of using it:

* It can run against the first untested PR or the first PR with a comment to force a test, or against the PR you specify.
 
  In this case you will need to run gitarro as many times as opened PRs requiring tests.  
  
  It works this way so if you are using Jenkins pulling the repository, you can have one job build for each gitarro execution.

  It is also posible instruct gitarro to scan only the Pull Requests changed during the last X seconds (--changed_since). From GitHub API perspective, and gitarro's perspective a change is either a new commit or a new comment at the PR.

* If you are using [webhooks](https://developer.github.com/webhooks/), then you just need to specify the ID of the Pull Requests that started the hook (--P or --PR)

It is also posible to tell gitarro to ignore PRs unless specific files are changed (by path or by extension with -f or --file), and specify a URL to added to the Pull Requests with the link to the log with the test output, for example to a Jenkins log (-u o --url).

# Current syntax:

```
Usage: gitarro.rb [options]

Mandatory options:
    -r, --repo 'REPO'                GitHub repository to look for PRs. For example: openSUSE/gitarro.
    -c, --context 'CONTEXT'          Context to set on comment (test name). For example: python-test.
    -t, --test 'TEST.SH'             Command, or full path to script/binary to be used to run the test.
    -g, --git_dir 'GIT_LOCAL_DIR'    Specify a location where gitarro will clone the GitHub project. If the dir does not exists, gitarro will create one. For example: /tmp/

Optional options:
    -f, --file '.py'                 pr_file type to filter/trigger the test against: .py, .rb
    -d, --description 'DESCRIPTION'  Test decription
    -C, --check                      Check if there is any PR requiring a test, but do not run it.
        --changelogtest              Check if the PR includes a changelog entry (Automatically sets --file ".changes").
    -u, --url 'TARGET_URL'           Specify the URL to append to add to the GitHub review. Usually you will use an URL to the Jenkins build log.
    -P                               '--PR 'NUMBER'
                                     Specify the PR number instead of checking all of them. This will force gitarro to run the against a specific PR number,even if it is not needed (useful for using Jenkins with GitHub webhooks).
        --https                      If present, use https instead of ssh for git operations
        --changed_since 'SECONDS'    If present, will only check PRs with a change in the last X seconds

Help:
    -h, --help                       help

Example: gitarro.rb -r openSUSE/gitarro -c 'python-test' -d 'someCoolTest' -g /tmp/pr-ruby01/ -t /tmp/test.sh -f '.py'
```

# Devel Installation

Use bundler to download all Ruby dependencies:

```console
bundler install
```

For the stable use `gem install gitarro`


# Configuration

The **only** configuration required is to have a valid ```/~.netrc``` file and a user that **read access credentials** to the repository with the Pull Requests to be tested.

You can use your GitHub username and password (unless you have [2FA](https://help.github.com/articles/about-two-factor-authentication/) enabled), but it is strongly recommended that you use a [GitHub Personal Token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)

Configure the ```/~.netrc``` with the following format (you can add a new line if the file already exists):

```machine api.github.com login <GITHUB_USER> password <GITHUB_PASSWORD/GITHUB_PERSONAL TOKEN>```

# Tests

Tipically you will have a shell script making all the work for you, including possible parameters (but again, it is possible to use any other scripting language, binaries or commands).

For example:

```bash
#!/bin/bash -e
rubocop *.rb
```

Would check Ruby source files for code that does not follow the [ruby style guide](https://github.com/bbatsov/ruby-style-guide). It will return 0 if everything is fine, or any other number if there are errors. With this return code gitarro is able to know if the test needs to be marked as failed 

Please take note that if you are using a script and decite to run it without calling the interpreter, it should be configured as executable.

# Syntax

Run the following command to get help

```console
gitarro.rb -h
```



[Documentation index](../README.md#documentation)
