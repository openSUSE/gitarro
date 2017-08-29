# Gitbot Documentation 


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

