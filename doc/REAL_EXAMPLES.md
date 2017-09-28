[Documentation index](../README.md#documentation)

# Real examples

Here are some real life examples so you can can see how easy is it to integrate gitarro with external tools.

## Checking gitarro ruby style with Jenkins

We will configure a job to teast a new PR made for an organization/gitarro GitHub repository (or a PR with a new [comment with the command to relaunch tests](ADVANCED.md#retriggering-a-specific-test))

So step by step:

* Make sure that the jenkins node which will run the job can access the ~/.netrc file, and that the file has credentials.
* Make sure that the jenkins node which will run the job has all the dependencies for Gitbot installed.
* Make sure that you have a file `/opt/ruby-checkstyle.sh` (ideally it should be checked out from a Git repository by Jenkins) with the following content:
 
 ```bash
 #! /bin/bash
 cd ${WORKSPACE}/gitarro
 rubocop
 ```
* Make sure that /opt/ruby-checkstyle.sh is configured as executable:
 
 ```chmod 755 /opt/ruby-checkstyle.sh```
* Configure the Jenkins job to clone ```https://github.com/organization/gitarro```
* Add the following script at ```Execute shell```:
 
 ```console
 ${WORKSPACE}/gitarro.rb
  -r organization/gitarro\
  -c "ruby_lint_checkstyle"\
  -d "Ruby linting tests"\
  -t "/opt/ruby-checkstyle.sh"\
  -u ${BUILD_URL}\
  -f ".rb"\
  -g "./"
 ```



[Documentation index](../README.md#documentation)
