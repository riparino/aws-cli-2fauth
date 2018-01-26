#!/usr/bin/bash
#
# This script must be sourced this no exit commands & nested if's

# Usage
if [ $# -ne 1 ]
then
  echo "Usage: $0 regionName"
  exit 255
fi

[[ $0 != "$BASH_SOURCE" ]] && sourced=1 || sourced=0
if [ "$sourced" -ne 1 ]
then
  echo "Usage: . ./sts.sh <-- Note the script is sourced"
else
  i=1
  echo -e "\nAvailable profiles:"
  for profile in $(grep "\[" ~/.aws/credentials | tr -d '[|]')
  do
    echo " $i) $profile"
    profileList[$i]=$profile
    i=$((i + 1))
  done
  printf "\nInput profile number: "
  read input
  profileName=${profileList[$input]}
  if [ -z "$profileName" ]; then
    echo "Unknown profile adios..."
  else
    echo
    export AWS_DEFAULT_PROFILE=$profileName
    echo "eval \$(AWS_PROFILE=$profileName get-aws-creds.sh)"
          eval  $(AWS_PROFILE=$profileName /bin/kash -p get-aws-creds.sh)

    regionName=$1
    aws ec2 describe-regions --region-names $regionName  >>/dev/null 2>&1
    if [ $? -gt 0 ]; then
      echo "ERROR: Invalid region: $regionName" 
    fi
    export AWS_DEFAULT_REGION=$regionName
    echo
    echo "Environment variables exported to your current shell:"
    echo "AWS_DEFAULT_PROFILE=$profileName"
    echo "AWS_DEFAULT_REGION=$regionName"
  fi
fi
