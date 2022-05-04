
## r2u:  R Binaries for Ubuntu

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/eddelbuettel/r2u)


### Key features

- **Full integration with `apt`** as every binary resolves _all_ dependencies: No
  more installations (of pre-built archives) only to discover that a shared
  library is missing. No more surprises.

- **Full integration with `apt`** so that an update of a system library
  cannot break an R package: if a (shared) library is used by a CRAN, the
  package manager knows and will not remove it.  No more (R package) breakage
  from (system) library updates.
  
- **Installations are fast, automated and reversible** thanks to package
  management layer


### What is Covered ?

We currently support amd64 (_i.e._ standard Intel/AMD cpus) for the 'focal'
20.04 LTS release.  An update to 22.04 is planned.  Support for other cpu
architectures is certainly possible but somewhat unlikely due to a lack of
(additional hardware) resources and time.

Support for other distributions is possible but unlikely right now (due to a lack
of resources and time). We hope to cover Debian ar some point.

R 4.2.0 is used, and BioConductor 3.15 packages are provided as required by CRAN packages.


### What is Selected ?

We use [cran-logs](https://cran-logs.rstudio.com/) and started by picking the _N_
most-downloaded packages, along with their dependencies from BioConductor.
(It should be noted that for example the first 100 packages already account
for approximately half the total downloads: a very skewed distribution.) We
iterated, and have now full coverage of CRAN.

So we now cover 
- *all CRAN packages( (modulo a handful of blacklisted ones) including all ~ 4500 CRAN packages needing compilation 
- all BioConductor package that are implied by these (and build for us). 

This currently resuls in 18954 binary packages from CRAN, and 177
BioConductor packages from the 3.15 release.


### What is it Based on?

For the CRAN binaries we either repackage RSPM builds (where available) or
build natively. All selected BioConductor 3.15 packages are built natively.
For all of these, full dependency resolution and integration with the system
is a key feature.

Everything is provided as `.deb` binary files with proper dependency
resolution by using a proper `apt` repo which also has a signed Release file.


### Usage 

(You could use [this script `add_cranapt.sh`](https://github.com/eddelbuettel/r2u/blob/master/inst/scripts/add_cranapt.sh) to facilitate the setup but you may prefer to execute the steps outlined here by
hand.)

First add the repository key so that `apt` knows it (this is optional but recommended) 

    apt install --yes --no-install-recommends gpg-agent  	# to add the key
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A1489FE2AB99A21A
    
Second, add the repository to the `apt` registry:

    echo "deb [arch=amd64] https://dirk.eddelbuettel.com/cranapt focal main" > /etc/apt/sources.list.d/cranapt.list
    apt update

Third, and optionally, if you do not yet have R 4.2.0 run these two lines (or
use the [standard CRAN repo setup](https://cloud.r-project.org/bin/linux/ubuntu/))

    echo "deb [arch=amd64] http://ppa.launchpad.net/edd/misc/ubuntu focal main" > /etc/apt/sources.list.d/edd-misc.list 
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 67C2D66C4B1D4339

Fourth, add repository 'pinning' as `apt` might get confused by some older
packages (in the Ubuntu distro) which accidentally appear with a higher
version number. See the next section to ensure 'CRANapt' sorts highest.

After that the package are known (under their `r-cran-*` and `r-bioc-*`
names).  You can install them on the command-line using `apt` and `apt-get`,
via `aptitude` as well as other front-ends.

Fifth, and also optional, install and enable the
[bspm](https://cloud.r-project.org/package=bspm) package so that CRANapt and
other packages become available via `install.packages()` and
`update.packages()`.



### Pinning

Because we let `apt` (and related tools) pick the packages, we have to ensure
that that the CRANapt repo sorts higher than the default repo as (older)
package builds in the distribution itself may appear (to `apt`) to be
newer. A case in point was package `gtable` whose version in Ubuntu was
`0.3.0+dfsg-1` which accidentally sorts higher than the rebuild we made under
a newer and more consistent version number `0.3.0-1.ca2004.1`.  One possible
fix is 'apt pinning'. Place a file `/etc/apt/preferences.d/99cranapt` with content

    Package: *
    Pin: origin "dirk.eddelbuettel.com"
    Pin-Priority: 700

which will now give packages from this repo a higher default priority of 700
overriding the standard value of 500.


## Docker

There is also a Docker container [eddelbuettel/r2u:focal](https://hub.docker.com/repository/docker/eddelbuettel/r2u)
that has the above, including pinning and [bspm](https://cran.r-project.org/package=bspm) support, already set up.


### Known Issues

As of early May:

- Some geospatial packages do not currently install, adding the UbuntuGIS PPA
  as a base may help as should basing builds on 22.04

- The littler package reflects build-time configuration, the RSPM binary is
  then expecting a different R location so it needs a binary rebuild. Added a
  'force' flag, may need a list similar to the blacklist to always compiled.
  
- A number of packages ship from RSPM as source. We catch those and/or use
  the force list to build them. 
  
- A small number of packages do not build for lack required components;
  examples are ROracle and Rcplex.  They, and their reverse dependencies, are
  are blacklisted and not built.

### Fixed Issues

- [DONE] The BioConductor release is still at 3.14 and should be upgraded to the
  now-current 3.15. 


### Author

Dirk Eddelbuettel

### License

The repository-building code in this package is released under the GPL (>= 2).

All CRAN and BioConductor packages are released under their respective licenses.

### Acknowledgment

This was made possible by the generous support of endless coffee thanks to my
[GitHub Sponsors](https://github.com/sponsors/eddelbuettel).
