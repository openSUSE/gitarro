#!/bin/bash -e
# Validate environment variables
if [ -z ${OPERATION} ]; then
  echo "ERROR: The variable OPERATION is not defined! Make sure you are starting the container with -e OPERATION=PR or -e OPERATION=NON-PR"
  exit 1
elif [ "${OPERATION}" == "PR" -a "${GITARRO_PARAMS}" = "" ]; then
  echo "ERROR: OPERATION=PR but the variable with the gitarro parameters does not exist! Make sure you are starting the container with -e GITARRO_PARAMS='<parameters>'"
  exit 1
elif [ "${OPERATION}" == "NON-PR" ]; then
  if [ "${GITHUB_REPO_URL}" = "" ]; then
    echo "ERROR: OPERATION=NON-PR but the variable with the GitHub repository does not exist! Make sure you are starting the container with -e GITHUB_REPO='<url>'"
    exit 1
  elif [ "${GIT_REF}" = "" ]; then
    echo "ERROR: OPERATION=NON-PR but the variable with the Git ref does not exist! Make sure you are starting the container with -e GIT_REF='<branch|commit|tag>'"
    exit 1
  fi
elif [ -z ${GITHUB_USER} ]; then
  echo "ERROR: The variable with GitHub users does not exist! Make sure you are starting the container with -e GITHUB_USER='<github_user>'"
  exit 1
elif [ -z ${GITHUB_PASSWORD} ]; then
  echo "ERROR: The variable with GitHub users does not exist! Make sure you are starting the container with -e GITHUB_PASSWORD='<github_password>'"
  exit 1
elif [ "$(echo ${SSH_PRIVATE_KEY})" == "" ]; then
  echo "WARNING: The variable SSH_PRIVATE_KEY does not exist. You will not be able to clone private repositories!"
fi

# Configure SSH private key only if needed
if [ "$(echo ${SSH_PRIVATE_KEY})" != "" ]; then
  echo "INFO: Configuring SSH private key..."
  echo "${SSH_PRIVATE_KEY}" > ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
fi

if [ "$(echo ${TEST_SCRIPT})" != "" ]; then
  echo -e "$TEST_SCRIPT"| sed -e 's/#\\!/#!/' > /tmp/test.sh
  chmod 755 /tmp/test.sh
fi

# PRs: Use gitarro with the parameters
if [ "${OPERATION}" == "PR" ]; then
  echo "INFO: Configuring ~/.netrc..."
  echo "machine api.github.com login ${GITHUB_USER} password ${GITHUB_PASSWORD}" > ~/.netrc && chmod 600 ~/.netrc
  echo "INFO: Running gitarro..."
  eval "ruby.ruby2.4 /opt/gitarro/gitarro.rb ${GITARRO_PARAMS}"
  echo "Return code of gitarro was ${?}"
  exit ${?}
# NON-PRs: Clone the repo, and run rubocop on its own
elif [ "${OPERATION}" == "NON-PR" ]; then
  echo "INFO: Cloning repository (reference ${GIT_REF})..."
  git clone --branch ${GIT_REF} --depth 1 ${GITHUB_REPO_URL} gitrepo
  cd gitrepo
  echo "INFO: Testing the following commit:"
  git log -1
  if [ ! -z ${RUBOCOP_TODO} ]; then
    echo "INFO: Reconfiguring rubocop_todo.yml..."
    echo "${RUBOCOP_TODO}" > rubocop_todo.yml
  fi
  echo "INFO: Running rubocop..."
  rubocop
  echo "Return code of rubocop was ${?}"
  exit ${?}
else
  echo "ERROR: Operation ${OPERATION} unknown! Make sure you are starting the container with -e OPERATION=PR or -e OPERATION=NON-PR"
  exit 1
fi
