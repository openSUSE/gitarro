# Gitbot Documentation 

```console
************************************************
Usage: gitbot [OPTIONS] 
 EXAMPLE: ======> ./gitbot.rb -r openSUSE/gitbot -c "pysthon-test" -d "pyflakes_linttest" -g /tmp/pr-ruby01/ -t /tmp/tests-to-be-executed -f ".py"

MANDATORY Options
    -r, --repo 'REPO'                github repo you want to run test against EXAMPLE: USER/REPO  MalloZup/gitbot
    -c, --context 'CONTEXT'          context to set on comment EXAMPLE: CONTEXT: python-test
    -d, --description 'DESCRIPTION'  description to set on comment
    -t, --test 'TEST.SH'             fullpath to thescript which contain test to be executed against pr
    -f, --file '.py'                 specify the file type of the pr which you wantto run the test against ex .py, .java, .rb
    -g, --git_dir 'GIT_LOCAL_DIR'    specify a location where gitbot will clone the github projectEXAMPLE : /tmp/pr-test/ if the dir doesnt exists, gitbot will create one.
OPTIONAL Options
    -u, --url TARGET_URL             specify the url to append to github review usually is the jenkins url of the job
        --changelogtest              check if the PR include a changelog entry. Automatically set --file ".changes"
    -C, --check                      check, if a PR requires testRun in checkmode and test if there is a Pull Request which requires a test
HELP
    -h, --help                       help
************************************************
```



## Basic design
Basically gitbot run a validation script/commands (-t) (could be bash, python, ruby, etc) against each open PR of your XXX Branch.

All open Pull-request will be then scanned for modifications on specific file type modified (-f ".py" as example). 
If the pr doesn't modify a python file( -f '.py') gitbot doesn't run a test against the pr.

If you have 10 untested PRs, you have to run it 10 times. 
Gitbot was especially so designed, because 1 run equals a 1 Jenkins Job.

The context  -c  is important: **make an unique context name** for each test category you want to run.
If you have same context name and the pr was already reviewed by gitbot, test will be not triggered.

EXAMPLE: 
```-c "python-pyflake", -c 'python-unit-tests'```

The context trigger the exec. of tests.

