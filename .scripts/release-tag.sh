#!/bin/bash

green="\e[32m"
red="\e[31m"
reset_color="\e[0m"

# Parse command line options.
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -help ) help=true; shift;;
    -major ) major=true; shift;;
    -minor ) minor=true; shift;;
    -patch ) patch=true; shift;;
    -dev ) dev=true; shift;;
    -rc ) rc=true; shift;;
    -alpha ) alpha=true; shift;;
    -beta ) beta=true; shift;;
    -clear ) clear=true; shift;;
    -dry ) dry=true; shift;;
    -f ) f=true; shift;;
    -version ) version="$2"; shift; shift;;
    -versionfile ) versionFile="$2"; shift; shift;;
  esac
done
set -- "${POSITIONAL[@]}"

if [ ! -z $help ]; then
  echo "#######################################################################"
  echo "usage: $(basename $0) [major|minor|patch]"
  echo ""
  echo "  -dry Dry run"
  echo "  -major for a major release"
  echo "  -minor for a minor release"
  echo "  -patch for a patch release"
  echo ""
  echo "  -rc    for adding -rcX suffix"
  echo "  -dev   for adding -dev suffix"
  echo "  -alpha for adding -alpha suffix"
  echo "  -beta  for adding -beta suffix"
  echo "  -clear for clearing suffix"
  echo ""
  echo "  -version for initializing version"
  echo "  -versionfile for file track of version instead of git tag"
  echo "#######################################################################"
  echo ""
  exit 0
fi

if [[ -z $major && -z $minor && -z $patch ]]; then
  patch=true
fi

# echo [$major] [$minor] [$patch]
# echo [$alpha] [$beta] [$dev] [$rc] [$clear]

# Force to the root of the project
pushd "$(dirname $0)/../"

if [[ -z $version && -z $versionFile ]]; then
  echo "Fetching Tags ..."
  git fetch --prune --tags

  version=$(git describe --abbrev=0 --tags)
fi

if [[ -z $version && ! -z $versionFile ]]; then
  if [ -f $versionFile ]; then
    version=$(cat $versionFile)
  else
    echo -e "${red}Version file missing: $versionFile${reset_color}"
    exit 1
  fi
fi

echo "Current Version: $version"

version=${version:1} # Remove the v in the tag v0.37.10 for example

rcVersion=0

tokens=( ${version//-/ } )
pRcVersion=${tokens[1]}

# obtain rc version
if [ ! -z pRcVersion ]; then
  rcVersion=${pRcVersion/rc/}
fi

# split version into major, minor, patch
tokens=( ${tokens[0]//./ } )

# if RC, alpha, beta, dev
if [[ -z $clear ]]; then
  if [[ ! -z $rc ]]; then
    ((rcVersion++))
    prefix="-rc$rcVersion"
  else
    if [[ ! -z $alpha ]]; then
      prefix='-alpha'
    else
      if [[ ! -z $beta ]]; then
        prefix='-beta'
      else
        if [[ ! -z $dev ]]; then
          prefix='-dev'
        fi
      fi
    fi
  fi
fi

if [[ ( -z $alpha && -z $beta && -z $dev && -z $rc && -z $clear ) || ! -z $f ]]; then
  inc=1
fi

# echo [$inc]

# if not rc, alpha, beta, dev or forced, increase version
if [[ ! -z $inc ]]; then
  if [[ ! -z $major ]]; then
    ((tokens[0]++))
    tokens[1]=0
    tokens[2]=0
  fi
  if [[ ! -z $minor ]]; then
    ((tokens[1]++))
    tokens[2]=0
  fi
  if [[ ! -z $patch ]]; then
    ((tokens[2]++))
  fi
fi

# compose version from version and rc/alpha/beta/dev prefix
version="v${tokens[0]}.${tokens[1]}.${tokens[2]}${prefix}"

# prepare commit message
userName=$(git config user.name)
message="Version increase to $version by $userName"

# # If its a dry run, just display the new release version number
if [[ ! -z $dry ]]; then
  echo "Tag message: $message"
  echo -e "${green}Next version: ${version}${reset_color}"
else
  if [[ ! -z $versionFile ]]; then
    echo $version > $versionFile
    git add $versionFile
    git commit $versionFile -m "$message"
  fi

  # Push master
  git push origin master

  # Add tag
  echo "Add git tag $version with message: $message"
  git tag -a "$version" -m "$message"

  # Push tag
  echo "Push the tag"
  git push --tags origin master

  echo -e "${green}Release tag done: ${version}${reset_color}"
fi

popd
