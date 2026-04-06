#!/bin/bash

## See the README.md of 'r2u' for details on these steps
##
## This script has been tested on a plain and minimal ubuntu:24.04
##
## On a well-connected machine this script should take well under one minute
##
## Note that you need to run this as root, or run the whole script via sudo
## To run individual commands as root, prefix each command with sudo and use
## 'echo | sudo tee file' as the command before the EOF redirect statement

set -eu

## First: update apt and get keys
apt update -qq && apt install --yes --no-install-recommends ca-certificates gnupg
## use gpg directly instead of the now-deprecated apt-key command
gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/r2u.gpg --keyserver keyserver.ubuntu.com --recv-keys A1489FE2AB99A21A 67C2D66C4B1D4339 51716619E084DAB9 F2B6E89C389782D0 5E25F516B04C661B
gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/r2u.gpg --export --armor A1489FE2AB99A21A > /etc/apt/trusted.gpg.d/eddelbuettel.asc
gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/r2u.gpg --export --armor F2B6E89C389782D0 5E25F516B04C661B > /etc/apt/trusted.gpg.d/rutter.asc
## Second: add the repo -- here we use the well-connected mirror
cat > /etc/apt/sources.list.d/r2u.sources <<EOF
Types: deb
URIs: http://r2u.stat.illinois.edu/ubuntu
Suites: resolute
Components: main
Arch: amd64, arm64
Signed-By: /etc/apt/trusted.gpg.d/eddelbuettel.asc
EOF

## Third: ensure current R is used
## For now use launchpad
#cat > /etc/apt/sources.list.d/cran.sources <<EOF
#Types: deb
#URIs: https://cloud.r-project.org/bin/linux/ubuntu
#Suites: noble-cran40/
#Components:
#Arch: amd64, arm64
#Signed-By: /usr/share/keyrings/r2u.gpg
#EOF
cat > /etc/apt/sources.list.d/rrutter.sources <<EOF
Types: deb
URIs: https://ppa.launchpadcontent.net/marutter/rrutter4.0/ubuntu/
Suites: resolute
Components: main
Enabled: yes
Signed-By: /etc/apt/trusted.gpg.d/rutter.asc
EOF

apt update -qq
DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends r-base-core

## Fourth: add pinning to ensure package sorting
cat > /etc/apt/preferences.d/99cranapt <<EOF
Package: *
Pin: release o=CRAN-Apt Project
Pin: release l=CRAN-Apt Packages
Pin-Priority: 700
EOF

## Fifth: install bspm (and its Python requirements) and enable it
## If needed (in bare container, say) install python tools for bspm and R itself
apt install --yes --no-install-recommends python3-{dbus,gi,apt} make
## Then install bspm (as root) and enable it, and enable a speed optimization
Rscript -e 'install.packages("bspm")'
cat >> /etc/R/Rprofile.site <<EOF
suppressMessages(bspm::enable())
options(bspm.version.check=FALSE)
EOF

# Done!
