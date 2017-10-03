[Documentation index](../README.md#documentation)

# Real examples

Here are some real life examples so you can can see how easy is it to integrate gitarro with external tools.

## Checking gitarro ruby style with Docker

1. Create a GitHub repository (we will call it upstream) with some ruby code (use extension .rb for your ruby files)

2. Fork upstream repository, and create a Pull Request changing at least on ruby file.

3. Follow the [instructions to configure .netrc](BASICS.md#configuration) so gitarro can interact with the upstream reposity using the API.

4. Assuming you have the docker daemon installed where you run gitarro, configure a test script called /tmp/ruby-checkstyle.sh
 
 ```console
 #!/bin/bash -e
 docker pull gitarro/docker-example:latest
 docker run --rm=true --name -ruby-style -v "/tmp/gitrepo:/opt/gitrepo gitarro/docker-example:latest
 ```
 This script will maje sure you have the most recent gitarro/docker-example image, and will launch a container with your local folder /tmp/gitrepo (you will use this path for Gitarro later on) binded as /opt/gitrepo, and finally will launch the test.

5. Now you can run Gitarro:
 
 ```console
 ./gitarro.rb -r organization/repo  -c "ruby_checkstyle" -d "Ruby checkstyle test" \
 -t "/tmp/ruby-checkstyle.sh" \
 -f ".rb" \
 -g "/tmp/gitrepo"
 ```
 
 Make sure you replace ```organization/repo````with the correct values for your upstream repository.
 
 This will check all the open Pull Requests with at least one file changed with extension '.rb' and will run rubocop for the first PR it finds. You will see how gitarro updates the status.

## Checking gitarro ruby style with Jenkins

We will configure a job to teast a new PR made for an organization/gitarro GitHub repository (or a PR with a new [comment with the command to relaunch tests](ADVANCED.md#retriggering-a-specific-test))

So step by step:

* Make sure that the jenkins node which will run the job can access the ~/.netrc file, and that the file has credentials.
* Make sure that the jenkins node which will run the job has all the dependencies for gitarro installed.
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
