# How to release a new gem of gitarro:

## Building a new gem of gitarro:

1) Update the version of the gem.

`vim gem/gitarro.gemspec`

Increase the number of version in chronological order xD

2) build the new gem with
```rake buildgem```

## Installing:
(Adapt with your gem number version.)

3) use `sudo gem install gem/gitarro-0.1.77.gem`


4) Release to rubygem.org

`gem push YOURGEM`


You should be one maintainer of gitarro. If you want to become one just open an issue on upstream.
