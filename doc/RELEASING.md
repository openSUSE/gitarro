# How to release a new gem of gitarro:

## Releasing at GitHub

1. Check that the version of the gem was updated (`gem/gitarro.gemspec`)
2. Check that CHANGELOG.md contains changes for the version

Create PRs as needed and get them merged.

## Building a new gem of gitarro

Adapt with your gem version.

1. Pull changes from the repository, including tags
2. Change to the tag for version you want to submit (for example `git checkout 0.1.77`)
3. build the new gem:
   `rake buildgem`

## Installing

Adapt with your gem version.

1. Install the gem:
   `sudo gem install gem/gitarro-0.1.77.gem`

2. Push the gem to rubygem.org
   `gem push gem/gitarro-0.1.77.gem`

For pushing you need to be maintainer of gitarro. If you want to become one just open an issue on upstream.
