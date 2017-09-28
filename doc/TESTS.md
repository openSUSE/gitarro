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

You can use the following command:

```console
cd tests/spec/
rspec -fd gitarro_cmdline_spec.rb
```



[Documentation index](../README.md#documentation)
