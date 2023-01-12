#!/bin/bash

## See README.md for details on these steps

## First: update apt and get gpg-agent and key
apt update -qq
apt install --yes --no-install-recommends gpg-agent  	# to add the key
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A1489FE2AB99A21A

## Second: add the repo -- here we now use the mirror
##echo "deb [arch=amd64] https://dirk.eddelbuettel.com/cranapt focal main" > /etc/apt/sources.list.d/cranapt.list
echo "deb [arch=amd64] https://r2u.stat.illinois.edu/ubuntu focal main" > /etc/apt/sources.list.d/cranapt.list
apt update

## Third: ensure current R is used
echo "deb [arch=amd64] https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" > /etc/apt/sources.list.d/edd-misc.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 67C2D66C4B1D4339

## Fourth: add pinning to ensure package sorting
echo "Package: *" > /etc/apt/preferences.d/99cranapt
echo "Pin: release o=CRAN-Apt Project" >> /etc/apt/preferences.d/99cranapt
echo "Pin: release l=CRAN-Apt Packages" >> /etc/apt/preferences.d/99cranapt
echo "Pin-Priority: 700"  >> /etc/apt/preferences.d/99cranapt

## Fifth: install bspm (and its Python requirements) and enable it
## If needed (in bare container, say) install python tools for bspm and R itself
apt install --yes python3-{dbus,gi,apt}
## Then install bspm (as root) and enable it
Rscript -e 'install.packages("bspm")'
RHOME=$(R RHOME)
echo "suppressMessages(bspm::enable())" >> ${RHOME}/etc/Rprofile.site
## Giving bspm sudo right used to be required but no longer is under current bspm versions
#echo "options(bspm.sudo=TRUE)" >> ${RHOME}/etc/Rprofile.site
