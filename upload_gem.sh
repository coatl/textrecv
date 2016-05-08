#!/bin/bash

#overall
#first get from https://rubygems.org/api/vi/api_key
  #with http basic auth of rubygems username and password
  #response is an api key

#then post to https://rubygems.org/api/v1/gems
  #with a body of the contents of the .gem file
  #and Authorization header set to the api key recvd above
  #Content-Type set to 'application/octet-stream'
  #Content-Length set to body size
  #?gem name is extracted from gemfile, not passed explicitly?

read -p "username: " username

#get api key
key=`
  textrecv --as-tarrunner \
    wget \
      --secure-protocol=PFS --auth-no-challenge \
      --user="$username" --ask-password \
      --no-verbose -O - \
      'https://rubygems.org/api/v1/api_key'
  `

if [ -z "$key" ]; then
  echo "failed to get api key" 2>&1
  exit
fi

#figure full path to gem to upload
file="$1"
[ "${file:0:1}" == "/" ] || file="`pwd`/$file"

#actually upload gem file
textrecv --as-tarrunner \
  wget \
    --secure-protocol=PFS \
    --post-file="$file" \
    --header="Authorization: $key" \
    --header="Content-Type: application/octet-stream" \
    'https://rubygems.org/api/v1/gems'

result=$?

key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

echo ignore error messages as long as http response was 200 OK

exit $result
