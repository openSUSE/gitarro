# Gitbot
![GUNDAM image](help/gundam.jpg)
![GUNDAM image](help/gundam.jpg)

[![Build Status Master branch](https://travis-ci.org/openSUSE/gitbot.svg?branch=master)](https://travis-ci.org/openSUSE/gitbot)

## Gitbot: automatize your Prs testing with your custom test env.
Gitbot allow you to run tests on prs. It run on each Systems that support ruby and octokit.

## 1) Installation:

```console
bundler install
```

## 2) Configuration:

The **only one** config is to have a valid ``` /~.netrc``` file and the user has to have **read access credentials** to the repo you want to test.
Configure the netrc file like this:

```
machine api.github.com login MY_GITHUB_USE password MY_PASSWORD
```

### 3) run it : 
```console
echo "#! /bin/bash" > /tmp/tests.sh
chmod +x tests.sh
ruby gitbot.rb -r openSUSE/gitbot -c "ruby-test" -d "ruby-gitbot-tuto" -g /tmp/pr-ruby01/ -t /tmp/tests.sh -f ".rb"
```


## Read real examples

[Real example](help/real_examples.md)

# Why gitbot?

Gitbot can execute test against Github prs.

The tests is an external custom validation script that will be executed against your branch.

In this way you can run all type of test on PRs and setting the status on github according to the test.

Furthermore in this way, you can run test in all type of env. like custom docker container(openSUSE, fedora, debian), or vms.

For gitbot the vms or script doesn't matter, since his focus is on scheduling the test and setting the status to you github project.


## Documentation
For more documentation refer to [Documentation](doc/README.md)

#### Advanced documentation

- Retrigger the jobs. [Advanced_doc](doc/ADVANCED.md)

