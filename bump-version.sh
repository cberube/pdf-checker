#!/bin/bash

set -e

if [ $# -ne 1 ]; then
  echo "Usage: `basename $0` <tag>"
  exit 65
fi


# CHECK MASTER BRANCH
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "master" ]]; then
  echo "You have to be on master branch currently on $CURRENT_BRANCH . Aborting"
  exit 65
fi

# CHECK FORMAT OF THE TAG
php -r "if(preg_match('/^\d+\.\d+\.\d+(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?\$/',\$argv[1])) exit(0) ;else{ echo 'format of version tag is not invalid' . PHP_EOL ; exit(1);}" $1


# CHECK jsawk COMMAND
command -v jsawk >/dev/null 2>&1 || { echo "Error : Command jsawk is not installed on the system"; echo "See : https://github.com/micha/jsawk "; echo  "Exiting..." >&2; exit 65; }

# CHECK js COMMAND
command -v js >/dev/null 2>&1 || { echo "Error : Command js is not installed on the system"; echo "Should be fixed by installing spidermonkey "; echo  "Exiting..." >&2; exit 65; }

# CHECK box COMMAND
command -v box >/dev/null 2>&1 || { echo "Error : Command box is not installed on the system"; echo "See : https://github.com/box-project/box2 "; echo  "Exiting..." >&2; exit 65; }

# CHECK python COMMAND
command -v python >/dev/null 2>&1 || { echo "Error : Command python is not installed on the system"; echo  "Exiting..." >&2; exit 65; }

# CHECK THAT WE CAN CHANGE BRANCH
git checkout gh-pages
git checkout --quiet master


TAG=$1


#
# Tag & build master branch
#
git checkout master
git tag ${TAG}
box build

#
# Copy executable file into GH pages
#
git checkout gh-pages

cp build/pdf-checker.phar downloads/pdf-checker-${TAG}.phar
cp build/pdf-checker.phar downloads/pdf-checker.phar
git add downloads/pdf-checker-${TAG}.phar
git add downloads/pdf-checker.phar

SHA1=$(sha1sum build/pdf-checker.phar | awk '{print $1}')

JSON='name:"pdf-checker.phar"'
JSON="${JSON},sha1:\"${SHA1}\""
JSON="${JSON},url:\"http://postalservice14.github.io/pdf-checker/downloads/pdf-checker-${TAG}.phar\""
JSON="${JSON},version:\"${TAG}\""

if [ -f pdf-checker.phar.pubkey ]; then
    cp pdf-checker.phar.pubkey pubkeys/pdf-checker-${TAG}.phar.pubkeys
    git add pubkeys/pdf-checker-${TAG}.phar.pubkeys
    JSON="${JSON},publicKey:\"http://postalservice14.github.io/MessageTester/pubkeys/pdf-checker-${TAG}.phar.pubkey\""
fi

#
# Update manifest
#
cat manifest.json | jsawk -a "this.push({${JSON}})" | python -mjson.tool > manifest.json.tmp
mv manifest.json.tmp manifest.json
git add manifest.json

git commit -m "Bump version ${TAG}"

#
# Go back to master
#
git checkout master

git push origin gh-pages
git push origin ${TAG}

echo "New version created. Now you should run:"
echo "git push origin gh-pages"
echo "git push origin ${TAG}"