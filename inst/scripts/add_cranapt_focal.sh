#!/bin/bash

## See the README.md of 'r2u' for details on these steps
##
## This script has been tested on a plain and minimal ubuntu:20.04
##
## On a well-connected machine this script should take well under one minute
##
## Note that you need to run this as root

## First: update apt and get keys
apt update -qq && apt install --yes --no-install-recommends gpg-agent gnupg ca-certificates
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A1489FE2AB99A21A

## Second: add the repo -- here we use the well-connected mirror
echo "deb [arch=amd64] https://r2u.stat.illinois.edu/ubuntu focal main" > /etc/apt/sources.list.d/cranapt.list

## Third: ensure current R is used
echo "deb [arch=amd64] https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" > /etc/apt/sources.list.d/cran-r.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 67C2D66C4B1D4339 51716619E084DAB9
apt update -qq
DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends r-base-core

## Fourth: add pinning to ensure package sorting
echo "Package: *" > /etc/apt/preferences.d/99cranapt
echo "Pin: release o=CRAN-Apt Project" >> /etc/apt/preferences.d/99cranapt
echo "Pin: release l=CRAN-Apt Packages" >> /etc/apt/preferences.d/99cranapt
echo "Pin-Priority: 700"  >> /etc/apt/preferences.d/99cranapt

## Fifth: install bspm (and its Python requirements) and enable it
## If needed (in bare container, say) install python tools for bspm and R itself
apt install --yes --no-install-recommends python3-{dbus,gi,apt} make
## Then install bspm (as root) and enable it, and enable a speed optimization
Rscript -e 'install.packages("bspm")'
RHOME=$(R RHOME)
echo "suppressMessages(bspm::enable())" >> ${RHOME}/etc/Rprofile.site
echo "options(bspm.version.check=FALSE)" >> ${RHOME}/etc/Rprofile.site
