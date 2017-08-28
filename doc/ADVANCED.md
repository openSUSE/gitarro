# Advanced doc Gitbot


## Retrigger a specific test.

For retrigger a specific test, you need to add a comment on the pr.

The user must be in the SUSE org for retrigger the tests, and the msg should have :


```@gitbot rerun TEST !!!``` ( at least !!!)

#### Example:

Assuming you want to rerun a test were the test is called: gitbot-magic:

- @gitbot rerun gitbot-magic ! (not working) (missed 2 of !!)
- @gitbot rerun gitbot-magic !!! (working)
- @gitbot rerun gitbot-magic !!!!!!! (working) ( at least 3 needed !!!)
- @gitbot rerun gitbot-magic2 !!!!!!! (not working) (typo)
- CIAO, we bla bla @gitbot rerun gitbot-magic !!!!!!! (will work) (but remember that the comment will deleted)
