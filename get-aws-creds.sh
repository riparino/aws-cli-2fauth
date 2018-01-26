#!/bin/ksh -p

# This uses MFA devices to get temporary (12 hour) credentials.  Requires
# a TTY for user input.

if [ ! -t 0 ]
then
  print Must be on a tty >&2
  exit 255
fi

if [ -n "$AWS_SESSION_TOKEN" ]
then
  print "Session token found.  This can not be used to generate a new token.
   unset AWS_SESSION_TOKEN AWS_SECRET_ACCESS_KEY AWS_ACCESS_KEY_ID
and then ensure you have a profile with the normal access key credentials or
set the variables to the normal keys.
" >&2
  exit 255
fi

identity=$(aws sts get-caller-identity)
username=$(print -- "$identity" | sed -n 's!.*"arn:aws:iam::.*:user/\(.*\)".*!\1!p')
if [ -z "$username" ]
then
  print "Can not identify who you are.  Looking for a line like
    arn:aws:iam::.....:user/FOO_BAR
but did not find one in the output of
  aws sts get-caller-identity

$identity" >&2
  exit 255
fi

print You are: $username >&2

mfa=$(aws iam list-mfa-devices --user-name "$username")
device=$(print -- "$mfa" | sed -n 's!.*"SerialNumber": "\(.*\)".*!\1!p')
if [ -z "$device" ]
then
  print "Can not find any MFA device for you.  Looking for a SerialNumber
but did not find one in the output of
  aws iam list-mfa-devices --username \"$username\"

$mfa" >&2
  exit 255
fi

print Your MFA device is: $device >&2

print -n "Enter your MFA code now: " >&2
read code

tokens=$(aws sts get-session-token --serial-number "$device" --token-code $code)

secret=$(print -- "$tokens" | sed -n 's!.*"SecretAccessKey": "\(.*\)".*!\1!p')
session=$(print -- "$tokens" | sed -n 's!.*"SessionToken": "\(.*\)".*!\1!p')
access=$(print -- "$tokens" | sed -n 's!.*"AccessKeyId": "\(.*\)".*!\1!p')
expire=$(print -- "$tokens" | sed -n 's!.*"Expiration": "\(.*\)".*!\1!p')

if [ -z "$secret" -o -z "$session" -o -z "$access" ]
then
  print "Unable to get temporary credentials.  Could not find secret/access/session entries

$tokens" >&2
  exit 255
fi

print export AWS_SESSION_TOKEN=$session
print export AWS_SECRET_ACCESS_KEY=$secret
print export AWS_ACCESS_KEY_ID=$access

print Keys valid until $expire >&2
