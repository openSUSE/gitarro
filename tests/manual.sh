#! /bin/bash

# some functional tests for gitbot !!

# Howto:
# this test should just run manual with a valid .netrc credentials
# the motivation of this test is because for faking PR and repos is a lot of efforts
# so for some important tests is better at this point to have this.

# PREREQUISITES:
# The repo should be a repo that your user in netrc can access.
# 0 netrc file
# 1 you should have at least on PR open for using this
# 2 you should write a comment '@gitbot rerun $context !!!' for test n3

repo="openSUSE/gitbot"
context="gitbot-dev"
desc="dev-test"
git_dir="/tmp/ruby0"
valid_test="/tmp/gitbot.sh"
url="https://github.com/openSUSE/gitbot/pull/8"
ftype='.rb'
echo '#! /bin/bash' > $valid_test
chmod +x $valid_test

# 0
echo 'testing normal behaviour'
ruby  ../gitbot.rb -r $repo  -c $context -d $desc -g $git_dir -t $valid_test -f $ftype -u $url
echo

# 1 test with check option enabled.
echo 'testing check option'

ruby  ../gitbot.rb -r $repo  -c "$context-01" -d $desc -g $git_dir -t $valid_test -f $ftype -u $url -C
if [ $? == 0  ]; then 
   echo "GIBOT TEST1 FAILED!!!!"
   exit 1
fi

# RETRIGGERING
# 2 test the retrigger with a word
# this imply you put a comment on the pr
# see prereq number 2

# the retrigger with check should just put the pr on pending.

echo "TESTING RETRIGGERING"

ruby  ../gitbot.rb -r $repo  -c $context -d $desc -g $git_dir -t $valid_test -f $ftype -u $url -C
ruby  ../gitbot.rb -r $repo  -c $context -d $desc -g $git_dir -t $valid_test -f $ftype -u $url

echo "TESTING CHANGELOG TEST"
# 3 test the changelog test
ruby  ../gitbot.rb -r $repo  -c "changelog" -d $desc -g $git_dir -t $valid_test -f $ftype -u $url --changelogtest

# 4 this, need a comment on pr no changelog needed!
ruby  ../gitbot.rb -r $repo  -c "changelog2" -d $desc -g $git_dir -t $valid_test -f $ftype -u $url --changelogtest

