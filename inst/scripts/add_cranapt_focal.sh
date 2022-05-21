#!/bin/bash

## See README.md for details on these steps

## First: update apt and get gpg-agent and key
apt update -qq
apt install --yes --no-install-recommends gpg-agent  	# to add the key
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A1489FE2AB99A21A

## Second: add the repo
echo "deb [arch=amd64] https://dirk.eddelbuettel.com/cranapt focal main" > /etc/apt/sources.list.d/cranapt.list
apt update

## Third: ensure R 4.2.0 is used
echo "deb [arch=amd64] https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" > /etc/apt/sources.list.d/edd-misc.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 67C2D66C4B1D4339

## Fourth: add pinning to ensure package sorting
echo "Package: *" > /etc/apt/preferences.d/99cranapt
echo "Pin: origin \"dirk.eddelbuettel.com\"" >> /etc/apt/preferences.d/99cranapt
echo "Pin-Priority: 700"  >> /etc/apt/preferences.d/99cranapt

## Fifth: install bspm and enable it
Rscript -e 'install.packages("bspm")'
RHOME=$(R RHOME)
echo "suppressMessages(bspm::enable())" >> ${RHOME}/etc/Rprofile.site
echo "options(bspm.sudo=TRUE)" >> ${RHOME}/etc/Rprofile.site
