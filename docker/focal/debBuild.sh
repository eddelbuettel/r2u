#!/bin/bash

set -e

progname=$(basename $0)
options=':a:bsh?'
## see https://stackoverflow.com/a/7948533/143305 for long options
usage_and_exit() {
    echo "Usage: ${progname} [-a pkgs] [-b] [-s] [-? | -h] pkg"
    echo ""
    echo "Build a .deb package from pkg"
    exit 0
}

aptpkgs=""
source="no"
repo="cran"

while getopts "${options}" i; do
    case "${i}" in
        a)	aptpkgs=$OPTARG
                ;;
        b)	repo="bioc"
                ;;
        s)	source="yes"
                ;;
        h|?)	usage_and_exit
          	;;
    esac
done

shift $((OPTIND-1))

if [ $# -ne 1 ]; then
    usage_and_exit
fi

pkg="$1"
lcpkg=$(echo "${pkg}" | tr '[A-Z]' '[a-z]')

if [ "${aptpkgs}" != "" ]; then
    apt update -qq
    apt install --yes --no-install-recommends ${aptpkgs}
fi

if [ "${source}" = "yes" ]; then
    cd /mnt/build/${pkg}/src
    R CMD INSTALL -l ../../${pkg}/debian/r-${repo}-${lcpkg}/usr/lib/R/site-library ${pkg}
    ## could cd .. and remove src/ now
fi

cd /mnt/build/${pkg}
dpkg-buildpackage -us -uc -d

cd ..
chown docker:staff *"${lcpkg}"*
chown -R docker:staff ${pkg}

## TODO: install into pool/ dir
mv -v r-${repo}-${lcpkg}_*.deb ../ubuntu/pool/main

## TODO: update index
cd ..
#./indexDebs.sh
