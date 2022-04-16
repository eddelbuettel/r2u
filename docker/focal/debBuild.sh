#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 pkg [deps ...]"
    exit 1
fi

pkg=$1
shift
lcpkg=$(echo "${pkg}" | tr '[A-Z]' '[a-z]')

if [ $# -gt 0 ]; then
    apt update -qq
    apt install --yes --no-install-recommends $@
fi

dpkg-buildpackage -us -us -d

cd ..
chown docker:staff *"${lcpkg}"*
chown -R docker:staff ${pkg}

mv r-cran-${lcpkg}_*.deb /deb/
