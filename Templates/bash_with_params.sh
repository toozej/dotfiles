#!/bin/bash -

# help/usage information
function usage {
    echo "Usage: SCRIPTNAME.sh [-c] [-r] REQUIREDPARAM"
    echo ""
    echo "  -h                  Display usage."
    echo ""
    echo "  -c                  something -c."
    echo ""
    echo "  -r                  something -r."
    echo ""
    echo "  REQUIREDPARAM       something required."
    echo "                        For example, blah."
    echo ""
    echo "  -d                  Debug mode."
    echo ""
}

function set_defaults {
    CHECK=false
    RUN=false
    DEBUG=false
    ANSIBLE_REPO_DIR=/tmp/ansible
}

# set defaults before getting user input
set_defaults

# get user input
while getopts ":hc:d:r:" option
do
  case $option in
    h)
      usage
      exit 1
      ;;
    c)
      CHECK=true
      ;;
    r)
      RUN=true
      ;;
    d)
      DEBUG=true
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done

echo "doing the thing"
