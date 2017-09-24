[Documentation index](../README.md#documentation)

# Retriggering a specific test

## Instructions

In order to retrigger a specific test, you need to add a comment to the PR.

**PLESE NOTE**: gitbot will delete the comment where you write the retriggering command, 
so make sure you use a separate comment for this.

Syntax:

```@gitbot rerun <test_name> !!!```

Notice that there is a space and three exclamation marks (``` !!!```) after the test name. This is required for the command to work.

## Examples

In this examples you want to rerun a test called gitbot-magic.

Valid examples:

* ```@gitbot rerun gitbot-magic !!!```
  
  It will work since there is a space and at least three exclamation marks after the test name.
* ```@gitbot rerun gitbot-magic !!!!!!!```
  
  It will work since there is a space and at least three exclamation marks after the test name.
* ```I discovered a bug so I need to run tests again, @gitbot rerun gitbot-magic !!!!!!!```
  
  It will work since there is a space and at least three exclamation marks after the test name, but **the whole comment will be removed** and the developer will loose it.

Invalid examples:

* ```@gitbot rerun gitbot-magic !```
 
  It will not work since there is a space after the test name, but less than three exclamation marks.
* ```@gitbot rerun gitbot-magic2 !!!!!!!```
 
  It will not work since there is a space and at least three exclamation marks after the test name, but the test name itself is incorrect.

# Check for PRs

This is useful if you are not using GitHub webhooks but polling the repository.

In this case you do not want to have a history with jobs that did not run tests for PRs, so you could have two jobs, one checking for PRs (without history) calling another that it actually only runs when there is something to check.

For the first you would run gitbot with exactly the same syntax, but adding the paramenter ```-C``` or ```--check``` what will only check if there are PRs requiring tests. If there is any, it will return 1 to the system, so you can use it to trigger the next job.

## Example

Following our [basic example](BASICS.md#a-basic-example), you will run gitbot as follows:

```console
ruby gitbot.rb -r openSUSE/gitbot -c "ruby-test" -d "ruby-gitbot-tuto" -g /tmp -t /tmp/tests.sh -f ".rb" -C
```



[Documentation index](../README.md#documentation)
