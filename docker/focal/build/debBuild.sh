#!/bin/bash

set -e

progname=$(basename $0)
options=':a:d:r:bsxh?'
## see https://stackoverflow.com/a/7948533/143305 for long options
usage_and_exit() {
    echo "Usage: ${progname} [-r r2udir] [-a pkgs] [-d dist] [-b] [-s] [-x] [-? | -h] pkg"
    echo ""
    echo "Build a .deb package from pkg"
    exit 0
}

aptpkgs=""
dist=""
source="no"
repo="cran"
xvfb=""
r2udir="/var/local/r2u"

while getopts "${options}" i; do
    case "${i}" in
        a)	aptpkgs=$OPTARG
                ;;
        d)	dist=$OPTARG
                ;;
        r)	r2udir=$OPTARG
                ;;
        b)	repo="bioc"
                ;;
        s)	source="yes"
                ;;
        x)	xvfb="yes"
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
    if [ ! -d ${r2udir}/build/${dist}/${pkg}/src ]; then
        mkdir -vp ${r2udir}/build/${dist}/${pkg}/src
    fi
    cd ${r2udir}/build/${dist}/${pkg}/src
    if [ "${xvfb}" = "yes" ]; then
        xvfb-run -a -n 20 R CMD INSTALL -l ../../${pkg}/debian/r-${repo}-${lcpkg}/usr/lib/R/site-library ${pkg}
    else
        R CMD INSTALL -l ../../${pkg}/debian/r-${repo}-${lcpkg}/usr/lib/R/site-library ${pkg}
    fi
    cd .. && rm -rf src
fi

cd ${r2udir}/build/${dist}/${pkg}
dpkg-buildpackage -us -uc -d -b

cd ..
chown docker:staff *"${lcpkg}"*
chown -R docker:staff ${pkg}

## TODO: install into pool/ dir
if [ ! -d ${r2udir}/ubuntu/pool/dists/${dist}/main ]; then
    mkdir -vp ${r2udir}/ubuntu/pool/dists/${dist}/main
fi
mv -v r-${repo}-${lcpkg}_*.deb ${r2udir}/ubuntu/pool/dists/${dist}/main

cd ..
