#!/usr/bin/env bash
set -e
set -u

echo "Generating API token..."

echo "Lookup credentials for login..."
RDUSER=$(awk -F= '/framework.server.username/ {print $2}' /etc/rundeck/framework.properties| tr -d ' ')
RDPASS=$(awk -F= '/framework.server.password/ {print $2}' /etc/rundeck/framework.properties| tr -d ' ')
SVR_URL=$(awk -F= '/framework.server.url/ {print $2}' /etc/rundeck/framework.properties | tr -d ' ')


CURLOPTS="-fsSL -c cookies -b cookies"
CURL="curl $CURLOPTS"

rm -rf ./cookies && echo "Removed previous cookies file" || echo "No cookies file to clear.. skipping"

# Authenticate
echo "authenticating..."
loginurl="${SVR_URL}/j_security_check"

$CURL $CURLOPTS -d "j_username=${RDUSER}" -d "j_password=${RDPASS}" $loginurl > curl.out

# Generate the API token.
echo "Requesting token..."
tokenurl="$SVR_URL/api/11/tokens/${RDUSER}"
$CURL -XPOST -L -c cookies -b cookies $tokenurl > curl.out
xmlstarlet fo -R curl.out > userprofile.xml 2>/dev/null

# Query the profile for the first apitoken.
token=$(xmlstarlet sel -t -v "//token/@id" userprofile.xml)

if [ -z "$token" ]
then
    echo >&2 "API token not found in the user profile."
    exit 1
fi
echo "Generated token: $token"
echo "$token" > token.out
