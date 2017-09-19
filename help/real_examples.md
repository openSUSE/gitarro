# Some real examples

You can see how easy it to integrate gitbot on external tools.

### With Docker

Configure a jenkins job like this. ( Make sure that in the jenkins node, the user jenkins can use the ~/.netrc file

The `$BUILD_URL` is a Env variable from jenkins, so we can give to github PR a way to debug  the test

At the beginning, gitbot will download the repo in /tmp/gitbot_java_lint

```console
/home/jenkins/bin/gitbot/gitbot.rb -r MalloZup/gibot \
 -c "java_lint_checkstyle" -d "linting tests" \
 -t "/home/jenkins/bin/valid-scripts/java-checkstyle.sh" \
 -u $BUILD_URL  \
 -f ".java" \
 -g "/tmp/gitbot_java_lint"

```

The script `java-checkstyle.sh` script is
```console
#! /bin/bash
  docker pull registry.mallo.net/test-image
  docker run --privileged --rm=true -v "mallo-local:/mallo-remote" registry.mallo.net/test-image /mallo-remote/java/lint.sh
```

So **gitbot** can use this script for validate PRs with docker and custom images.
This test template is  a real example (beside of faking the names)
