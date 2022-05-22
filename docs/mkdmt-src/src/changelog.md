###  2022 

2022-05-22  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Reword headline 
 
2022-05-21  Dirk Eddelbuettel  <edd@debian.org> 
 
        * inst/scripts/add_cranapt_focal.sh: Use CRAN repo for R 
        * README.md: Ditto 
 
2022-05-20  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/controlFiles.R: Reflect repo in Description: 
 
2022-05-17  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/controlFiles.R: Build and cache in per distro dir 
        * R/package.R: Ditto 
        * docker/*/build/debBuild.sh: Add dist argument 
        * README.md: Update package numbers 
 
2022-05-15  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/controlFiles.R: Correct base package list 
        * R/init.R: Filter commented lines from blacklist 
        * R/package.R: New helper to identify updated packages 
 
2022-05-13  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: New top-level function to build updated packages 
        * R/init.R: Support 
        * man/buildPackage.Rd: Docs 
 
        * README.md: Update package numbers 
 
2022-05-11  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Switch instruction to downloading keys and storing in 
        /etc/apt/trusted.gpg.d/ which is now preferred, additional edits 
 
2022-05-09  Dirk Eddelbuettel  <edd@debian.org> 
 
        * inst/scripts/add_cranapt_jammy.sh: Update key use 
 
        * R/init.R: Correct a cached=file time comparison 
 
2022-05-08  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: Add nDeps 
 
        * docker/jammy/run/Dockerfile: Use asc key file 
 
        * .gitpod.Dockerfile: Switch to 22.04 
 
2022-05-07  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Updated docs 
        * docs/*: Idem 
 
        * docker/jammy/build/*: Use http instead of mount for pinning 
        * docker/jammy/build/debBuild.sh: Call dpkg-buildpackage with -b 
 
        * inst/scripts/add_cranapt_focal.sh: Renamed from add_cranapt.sh 
        * inst/scripts/add_cranapt_jammy.sh: Added 
 
2022-05-06  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: Support building for multiple LTS releases 
        * R/init.R: Idem, skip test for R >= 4.0, two-tiered depends 
        * DESCRIPTION: Depend on R >= 4.0 
 
2022-05-04  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: Simpler interface 
 
        * inst/examples/add_cranapt.sh: Renamed from setup_r2u.sh 
 
        * README.md: Documentation updates 
 
2022-05-03  Dirk Eddelbuettel  <edd@debian.org> 
 
        * Initial version 
