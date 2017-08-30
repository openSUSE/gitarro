# Advanced doc Gitbot


## Retrigger a specific test.

In order to retrigger a specific test, you need to add a comment to the PR.

**TAKE CARE**: gitbot will delete the comment where you write the retriggering magic word, 
so make sure you write the retrigger in a different comment.


The user must be in the SUSE org to retrigger the tests, and the msg should have:


```@gitbot rerun TEST !!!``` ( at least !!!)

#### Example:

Assuming you want to rerun a test were the test is called: gitbot-magic:

- @gitbot rerun gitbot-magic ! (not working, 2 !! missing)
- @gitbot rerun gitbot-magic !!! (working)
- @gitbot rerun gitbot-magic !!!!!!! (working) (at least 3 !!! needed)
- @gitbot rerun gitbot-magic2 !!!!!!! (not working, typo)
- CIAO, we bla bla @gitbot rerun gitbot-magic !!!!!!! (will work, but remember that the comment will be deleted)
