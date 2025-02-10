###  2025 

2025-02-10  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/init.R: Robustify build when no config directory present 
 
###  2024 

2024-11-04  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Document BioConductor 3.20 support 
 
2024-10-30  Dirk Eddelbuettel  <edd@debian.org> 
 
        * inst/scripts/add_cranapt_noble.sh: Updated to use gpg instead of 
        apt-key (following issue #72) 
 
        * README.md: Mentioned updated 'noble' aka 24.04 script too 
 
2024-10-16  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Updated usage figures and chart (from late September) 
 
2024-09-03  Dirk Eddelbuettel  <edd@debian.org> 
 
        * DESCRIPTION (Authors@R): Added 
 
2024-07-15  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Update package counts 
 
2024-06-01  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Update usage section showing 20 million total downloads 
 
2024-05-13  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Document BioConductor 3.19 support across all three 
        supported releases (now that 22.04 and 20.04 both caught up) 
 
2024-05-12  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Document 24.04 support 
 
        * inst/scripts/add_cranapt_noble.sh: Add new 24.04 install script 
 
2024-05-11  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R (.get_source_file): Always download source file if 
        'force' and 'compile' are set 
        * R/controlFiles.R (.addDepends): Refine one regular expression 
 
2024-05-10  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/init.R: Support Ubuntu 24.04 
        * R/package.R: Idem 
        * inst/scripts/add_cranapt_noble.sh: Idem 
        * docker/noble/*: Build and run-time support for 24.04 
 
2024-04-12  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/init.R (.loadRuntimedepends): Support run-time dependency 
        declarations via config file 
        * R/controlFiles.R (.addDepends): Show run-time dependencies 
        * R/package.R (buildPackage): Source run-time dependency file 
 
2024-03-25  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Update usage numbers and charts 
 
2024-02-23  Dirk Eddelbuettel  <edd@debian.org> 
 
        * vignettes/FAQ.md: Expanded FAQ, link FAQ from ToC 
 
2024-02-16  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: More consistent color use 
 
2024-02-12  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: Package version display small correction, display 
        source repo more prominently 
 
2024-02-11  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: Package version display tweak 
 
2024-02-09  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Update usage counts 
 
###  2023 

2023-12-18  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Document r2u use in GitHub Actions 
 
2023-12-12  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Updated totals and count 
 
2023-11-11  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: Add new '--compile' flag to force source build 
 
2023-11-10  Dirk Eddelbuettel  <edd@debian.org> 
 
        * repo: Rebuilt a number of packages following Matrix update 
        following discussion and analysis with Mikael Jagan 
 
2023-11-05  Dirk Eddelbuettel  <edd@debian.org> 
 
        * repo: Expanded BioConductor support adding over 100 packages 
 
2023-11-04  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Mention R 4.3.2 is now the R version used and provided, 
        update package counts from CRAN and BioConductor 
 
        * repo: Rebuild of BioConductor packages for 3.18 release 
 
2023-10-09  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R (buildPackage): Support new argument 'dryrun' 
 
2023-09-02  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: Extended to also update BioConductor packages 
        * R/init.R: Idem 
 
2023-08-20  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Small edits and minor clarification 
 
2023-08-16  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/init.R (.setOptions): Set timeout to 180 
 
2023-08-15  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: A few edits throughout 
 
2023-08-13  Dirk Eddelbuettel  <edd@debian.org> 
 
        * docs/*: Added new vignette on 'codespaces' 
 
2023-08-12  Dirk Eddelbuettel  <edd@debian.org> 
 
        * .devcontainers/*: Adding documentation for Devcontainer use 
 
2023-08-09  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/init.R (.setOptions): Set timeout to 300 
 
2023-06-03  Dirk Eddelbuettel  <edd@debian.org> 
 
        * repo: The metadata for focal (20.04) has been adjusted so packages 
        `sf`, `gdalraster` and `FIESTA` are now available as on 22.04 
 
2023-05-11  Dirk Eddelbuettel  <edd@debian.org> 
 
        * .gitpod.Dockerfile: Update to rocker/r2u:jammy 
        * .gitpod.yml (vscode): Update to REditorSupport.r@2.8.0 
 
2023-05-09  Dirk Eddelbuettel  <edd@debian.org> 
 
        * repo: Several packages using the Graphics API of R itself have been 
        rebuilt for R 4.3.0 and its 'soft' API change  
 
2023-04-29  Dirk Eddelbuettel  <edd@debian.org> 
 
        * repo: Rebuild of BioConductor packages for 3.17 release 
 
2023-04-25  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Mention R 4.3.0 is now the R version used 
 
2023-04-14  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Mention rocker/r2u containers 
 
###  2022 

2022-12-25  Dirk Eddelbuettel  <edd@debian.org> 
 
        * docs/mkdmt-src/src/vignettes/FAQ.md: Mention that non-LTS releases 
        can use the LTS repos just fine. 
 
2022-11-19  Dirk Eddelbuettel  <edd@debian.org> 
 
        * inst/NEWS.Rd: Make release 0.0.4 with BioConductor 3.16 
 
2022-09-18  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Mention that Docker build cannot use bspm as the 
        security setting used at run-time is not available during build time 
        * inst/docs/FAQ.md: Idem 
 
2022-09-16  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Mention the new mirror r2u.stat.illinois.edu 
        * inst/scripts/add_cranapt_focal.sh: Use r2u.stat.illinois.edu 
        * inst/scripts/add_cranapt_jammy.sh: Idem 
        * docker/focal/run/cranapt.list: Idem 
        * docker/jammy/run/cranapt.list: Idem 
 
2022-09-14  John Blischak  <jdblischak@gmail.com> 
 
        * inst/scripts/add_cranapt_jammy.sh: Add missing 'apt update' 
 
2022-09-11  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Update to state 'current R' via CRAN apt repo 
        * inst/scripts/add_cranapt_focal.sh: Idem 
        * inst/scripts/add_cranapt_jammy.sh: Idem 
 
2022-09-08  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md: Update package number 
 
2022-08-01  Dirk Eddelbuettel  <edd@debian.org> 
 
        * inst/dockerize/Dockerfile: Add 'dockerize' example 
        * inst/dockerize/README.md: Short description 
 
2022-07-12  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/controlFiles.R (.addDepends): Special-case 'rJava' which does not 
         resolve its shared library given that Java libs are hidden 
 
2022-07-07  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/init.R (.loadDB, .loadAP): Make cache age a function parameter 
 
2022-06-18  Dirk Eddelbuettel  <edd@debian.org> 
 
        * README.md (Pinning): Refined setup with origin and label 
        * inst/scripts/add_cranapt_{focal,jammy}.sh: Idem 
        * docker/{focal,jammy}/{build,run}: Idem 
 
2022-06-17  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R (buildPackage): Correct nlme and foreign download 
 
2022-06-08  Dirk Eddelbuettel  <edd@debian.org> 
 
        * inst/docs/FAQ.md: Add entry on Singularity 
 
2022-06-06  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/controlFiles.R: Accomodate sp with epoch 
        * README.md: Edits 
 
2022-06-02  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: Accomodate dash-to-dot in nlme and foreign versions 
 
2022-06-01  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/controlFiles.R: Accomodate dash-to-dot in foreign version 
 
2022-05-31  Dirk Eddelbuettel  <edd@debian.org> 
 
        * inst/docs/FAQ.md: Draft of two new entries 
 
2022-05-29  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: Correct two invisible calls 
        * R/controlFiles.R: Accomodate dash-to-dot in nlme version 
 
2022-05-28  Sergio Oller  <sergioller@gmail.com> 
 
        * README.md: Add missing double-quote in example 
 
2022-05-25  Dirk Eddelbuettel  <edd@debian.org> 
 
        * R/package.R: Support per-distribution blacklist 
        * R/init.R: Idem 
 
        * docker/focal/run/Dockerfile: Note '--security-opt 
        seccomp=unconfined' needed for bspm use 
 
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
