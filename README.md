# Gitbot
![GUNDAM image](help/gundam.jpg)
![GUNDAM image](help/gundam.jpg)

[![Build Status Master branch](https://travis-ci.org/MalloZup/gitbot.svg?branch=master)](https://travis-ci.org/MalloZup/gitbot)

## Gitbot: automatize your Prs testing with your custom test env.
Gitbot allow you to run tests on prs. It run on each Systems that support ruby and octokit.

### Read real examples

[Real example](help/real_examples.md)

# Why gitbot?

Gitbot was developed. to run jenkins job against a repo.
It differs from travis because it's not limited on container or others limited env, it just run everywhere.

Like in custom jenkins server or vms(OS indipendent), or in custum containers.


## 1) Installation:

```console
gem install octokit
gem install netrc
```

## 2) Configuration:

The **only one** config is to have a valid ``` /~.netrc``` file and the user has to have **read access credentials** to the repo you want to test.
Configure the netrc file like this:

```
machine api.github.com login MY_GITHUB_USE password MY_PASSWORD
```

### 3) run it : USAGE:
************************************************
```console
************************************************
Usage: gitbot [OPTIONS] 
 EXAMPLE: ======> ./gitbot.rb -r MalloZup/galaxy-botkins -c "python-test" -d "pyflakes_linttest" -g /tmp/pr-ruby01/ -t /tmp/tests-to-be-executed -f ".py"

MANDATORY Options
    -r, --repo 'REPO'                github repo you want to run test against EXAMPLE: USER/REPO  MalloZup/gitbot
    -c, --context 'CONTEXT'          context to set on comment EXAMPLE: CONTEXT: python-test
    -d, --description 'DESCRIPTION'  description to set on comment
    -t, --test 'TEST.SH'             fullpath to thescript which contain test to be executed against pr
    -f, --file '.py'                 specify the file type of the pr which you wantto run the test against ex .py, .java, .rb
    -g, --git_dir 'GIT_LOCAL_DIR'    specify a location where gitbot will clone the github projectEXAMPLE : /tmp/pr-test/ if the dir doesnt exists, gitbot will create one.
OPTIONAL Options
    -u, --url TARGET_URL             specify the url to append to github review usually is the jenkins url of the job
    -s, --secs TIMEOUT               specify the secs you want to wait/sleep if the gitbot is not finding any valid PRs to review. (usefull to spare jenkins jobs history)
HELP
    -h, --help                       help
************************************************
```

Basically gitbot run a validation script/commands (-t) (could be bash, python, ruby) against each open PR of your XXX Branch.
The Open Pull-request will then scanned for modifications on specific file type modified (-f ".py" as example). If the pr doesn't modify a python file( -f '.py') gitbot doesn't run a test against the pr.

If you have 10 untested PRs, you have to run it 10 times. 
Gitbot was especially so designed, because 1 run equals a 1 Jenkins Job.

The context  -c  is important: **make an unique context name** for each test category you want to run.
If you have same context name and the pr was already reviewed by gitbot, test will be not triggered.

EXAMPLE: 
```-c "python-pyflake", -c 'python-unit-tests'```

The context trigger the exec. of tests.


************************************************
