###  2022 

2022-05-07  Dirk Eddelbuettel  <edd@debian.org> 
 
        * docker/jamm/build/*: Use http instead of mount for pinning 
        * docker/jammy/build/debBuild.sh: Call dpkg-buildpackage with -b 
 
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