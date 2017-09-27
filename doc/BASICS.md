[Documentation index](../README.md#documentation)

# Basic concepts

gitbot runs a validation script, binary or command (-t or --test) against PRs of the GitHub repository you specify (-r or --repo) .

There are two basic ways of using it:

* It can run against the first untested PR or the first PR with a comment to force a test, or against the PR you specify.
 
  In this case you will need to run gitbot as many times as opened PRs requiring tests.  
  
  It works this way so if you are using Jenkins pulling the repository, you can have one job build for each gitbot execution.

* If you are using [webhooks](https://developer.github.com/webhooks/), then you just need to specify the ID of the Pull Requests that started the hook (--P or --PR)

It is also posible to tell gitbot to ignore PRs unless specific files are changed (by path or by extension with -f or --file), and specify a URL to added to the Pull Requests with the link to the log with the test output, for example to a Jenkins log (-u o --url).

# Current syntax:

```
Usage: gitbot.rb [options]

Mandatory options:
    -r, --repo 'REPO'                GitHub repository to look for PRs. For example: openSUSE/gitbot.
    -c, --context 'CONTEXT'          Context to set on comment (test name). For example: python-test.
    -t, --test 'TEST.SH'             Command, or full path to script/binary to be used to run the test.
    -f, --file '.py'                 pr_file type to run the test against: .py, .rb
    -g, --git_dir 'GIT_LOCAL_DIR'    Specify a location where gitbot will clone the GitHub project. If the dir does not exists, gitbot will create one. For example: /tmp/

Optional options:
    -d, --description 'DESCRIPTION'  Test decription
    -C, --check                      Check if there is any PR requiring a test, but do not run it.
        --changelogtest              Check if the PR includes a changelog entry (Automatically sets --file ".changes").
    -u, --url 'TARGET_URL'           Specify the URL to append to add to the GitHub review. Usually you will use an URL to the Jenkins build log.
    -P                               '--PR 'NUMBER'
                                     Specify the PR number instead of checking all of them. This will force gitbot to run the against a specific PR number,even if it is not needed (useful for using Jenkins with GitHub webhooks).
        --https                      If present, use https instead of ssh for git operations

Help:
    -h, --help                       help

Example: gitbot.rb -r openSUSE/gitbot -c 'python-test' -d 'someCoolTest' -g /tmp/pr-ruby01/ -t /tmp/test.sh -f '.py'
```

# Installation

Use bundler to download all Ruby dependencies:

```console
bundler install
```

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

Would check Ruby source files for code that does not follow the [ruby style guide](https://github.com/bbatsov/ruby-style-guide). It will return 0 if everything is fine, or any other number if there are errors. With this return code gitbot is able to know if the test needs to be marked as failed 

Please take note that if you are using a script and decite to run it without calling the interpreter, it should be configured as executable.

# Syntax

Run the following command to get help

```console
ruby gitbot.rb -h
```

# A basic example

```console
echo "#! /bin/bash" > /tmp/tests.sh
chmod +x /tmp/tests.sh
ruby gitbot.rb -r openSUSE/gitbot -c "ruby-test" -d "ruby-gitbot-tuto" -g /tmp -t /tmp/tests.sh -f ".rb"
```



[Documentation index](../README.md#documentation)
