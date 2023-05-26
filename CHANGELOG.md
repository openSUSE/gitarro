# Changelog Gitarro

## 0.1.91

- Implement split/merge method in the changelog test
- Fix typo in 'faraday' entry in the Gemfile

## 0.1.90

- Don't uncheck re-run boxes in check mode as those will be checked again in the next gitarro run triggering the test

## 0.1.89

- Fix faraday version to work with ruby 2.5

## 0.1.88

- Skip test if there is a job status for it to avoid spurious reruns on long tests

## 0.1.87

- Fix regular expression to Re-run tests

## 0.1.86

- Triggered_by_pr_number method removed
- We will use --PR parameter only to don't iterate through all open PRs
- Force_test parameter added. it force to run a test, even if is not marked to be re-triggered
- Accept X or x for PR checkboxes, extra whitespaces, and be case-insensitive

## 0.1.85

- uncheck the re-run checkbox even if --check option is passed by parameter
- triggered_by_pr_number will trigger a concrete PR by doing the same checks than unreviewed_new_pr

## 0.1.84

- Fix the bug discussed in #166
- Add a comment after unmark a rerun test checkbox, in case the test does not apply

## 0.1.83

- Hot-fix 0.1.82, retriggered_by_comment had a change in the signature

## 0.1.82

- Added Changelog
- [6346] Allow skipping changelog test from description
