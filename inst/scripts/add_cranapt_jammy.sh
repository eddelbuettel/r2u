#!/bin/bash

## See README.md for details on these steps
##
## This script has been tested on a plain ubuntu:22.04 system having R
##
## Note that you need to run this as root

## First: update apt and get wget to fetch keys
apt update -qq
apt install --yes --no-install-recommends wget ca-certificates

## Second: add the CRAN apt repo and key -- here we now use the mirror
wget -q -O- https://eddelbuettel.github.io/r2u/assets/dirk_eddelbuettel_key.asc \
    | tee -a /etc/apt/trusted.gpg.d/cranapt_key.asc
##echo "deb [arch=amd64] https://dirk.eddelbuettel.com/cranapt jammy main" > /etc/apt/sources.list.d/cranapt.list
echo "deb [arch=amd64] https://r2u.stat.illinois.edu/ubuntu jammy main" > /etc/apt/sources.list.d/cranapt.list
apt update

## Third: ensure current R is used (could use Launchpad source or edd PPA too)
wget -q -O- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
    | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
echo "deb [arch=amd64] https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/" > /etc/apt/sources.list.d/cran_r.list

## Fourth: add pinning to ensure package sorting
echo "Package: *" > /etc/apt/preferences.d/99cranapt
echo "Pin: release o=CRAN-Apt Project" >> /etc/apt/preferences.d/99cranapt
echo "Pin: release l=CRAN-Apt Packages" >> /etc/apt/preferences.d/99cranapt
echo "Pin-Priority: 700"  >> /etc/apt/preferences.d/99cranapt

## Fifth: install bspm and enable it
## If needed (in bare container, say) install python tools for bspm and R itself
apt install --yes python3-{dbus,gi,apt}
## Then install bspm (as root) and enable it
Rscript -e 'install.packages("bspm")'
export RHOME=$(R RHOME)
echo "suppressMessages(bspm::enable())" >> ${RHOME}/etc/Rprofile.site
## Giving bspm sudo right used to be required but no longer is under current bspm versions
#echo "options(bspm.sudo=TRUE)" >> ${RHOME}/etc/Rprofile.site
