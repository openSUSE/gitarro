[Documentation index](../README.md#documentation)

# gitarro tests

## Unit tests 

These tests run automatically on Travis for new [PRs](https://travis-ci.org/openSUSE/gitarro/pull_requests) or when a [special comment at a PR](ADVANCED.md#retriggering-a-specific-test) triggers them.

The tests will also run when a [branch changes](https://travis-ci.org/openSUSE/gitarro/branches), for example after a PR is merged

You must **always** run them locally before creating a PR or after you change your PR.

You can use the following command:

```console
rake test
```

## Acceptance tests

These tests use [rspec](http://rspec.info/) are not executed on travis, so you need to launch the execution manually.


**Run your tests always on your forked repo!**

### Syntax variables

You need a fixed PR open for running some tests.
REPO is the value of your forked repo.
PR_NUM is the pr of the fake repo on your forked repo (this is needed for testing)

Syntax:
```console
 +repo=<REPO> pr_num=<PR_NUM> rspec -fd cmdline_spec.rb
```

Where ```REPO``` is your repository in format ```project/repo``` and ```PR_NUM``` is an opened and mergeable Pull Request.


How to run them:

#### Via rake (best way)

Then create a file called: `.rspec.yml`
And put your Repo and PR_Number in yml. (this file is ignored by git)

```yaml
repo: MalloZup/gitarro
pr_num: 1
```

Then run the tests with
``` rake spec```

#### Manually (using rspec)
For example:

```console
 cd tests/spec/
repo=MalloZup/gitarro pr_num=1 rspec -fd cmdline_spec.rb
```

[Documentation index](../README.md#documentation)
