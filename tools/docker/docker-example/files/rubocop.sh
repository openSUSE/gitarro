#!/bin/bash -e
if [ ! -d /opt/gitrepo ]; then
  echo "ERROR: You did not specicfied a bind mount!"
  exit 1
fi
cd /opt/gitrepo
echo "INFO: Testing the following commit:"
git log -1
echo "INFO: Running rubocop..."
ruby.ruby2.4 /opt/rubocop/bin/rubocop
echo "Return code of rubocop was ${?}"
exit ${?}
