
## r2u:  R Binaries for Ubuntu

Key features:

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

We currently support amd64 (_i.e._ standard Intel/AMD cpus) for the _focal_
20.04 LTS release.  An update to 22.04 is planned.

Support for other cpu architectures is certainly possible but somewhat
unlikely due to a lack of (additional hardware) resources and time.

Support for other distributions is possible but unlikely right now (due to a lack
of resources and time). We hope to cover Debian ar some point.

### What is Selected ?

We use [cran-logs](https://cran-logs.rstudio.com/) and pick the _N_
most-downloaded packages, along with their dependencies from BioConductor.
(It should be noted that the first 100 packages account for approximately
half the total downloads: a very skewed distribution.)

In this first stage, we cover 
- the top eight thousand (or just over 40% of) CRAN packages (by downloads) 
- as well as 100% of the ~ 4500 CRAN packages needing compilation 
- and whichever many BioConductor package are implied by these (and build). 

As there is overlap between the set, we currently have around 11400 binary
packages, or about 60% of the total of CRAN packages.

### What is Based on?

For the CRAN binaries we repackage RSPM builds, and add full dependency
resolution and integration with the system.

The BioConductor packages are built natively.

Everything is provided as `.deb` binary files with proper dependency using a
proper `apt` repo with a signed Release file.


### Usage 

To use the repo, first (and this is optional) add the repository key

    apt install gpg-agent                        		# to add the key
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A1489FE2AB99A21A
    
Second, add the repository itself to the `apt` registry:

    echo "deb [arch=amd64] https://dirk.eddelbuettel.com/cranpt focal main" > /etc/apt/sources.list.d/cranapt.list
    apt update

After that the package are known (under their `r-cran-*` and `r-bioc-*`
names).  You can install them on the command-line using `apt` and `apt-get`,
via `aptitude` as well as other front-ends.

If you add and enable [bspm](https://cloud.r-project.org/package=bspm)
they become available via `install.packages()` and `update.packages()`.

### Pinning

Because we let `apt` (and related tools) pick the packages, we have to ensure
that that the CRANapt repo sorts higher than the default repo as (older)
package builds in the distribution itself may appear (to `apt`) to be
newer. A case in point was package `gtable` whose version in Ubuntu was
`0.3.0+dfsg-1` which accidentally sorts higher than the rebuild we made under
a newer and more consistent version number `0.3.0-1.ca2004.1`.  One possible
fix is 'apt pinning'. Place a file `/etc/apt/preferences.d/99cranpt` with content

    Package: *
    Pin: origin "dirk.eddelbuettel.com"
    Pin-Priority: 700

which will now give packages from this repo a higher default priority of 700
overriding the standard value of 500.

### Known Issues

As of late April:

- Some geospatial packages do not currently install, adding the UbuntuGIS PPA
  as a base may help

- The BioConductor release is still at 3.14 and should be upgraded to the
  now-current 3.15. 

### Author

Dirk Eddelbuettel

### License

All CRAN packages are released under their respective licenses.

### Acknowledgment

This was made possible by the generous support of endless coffee thanks to my
[GitHub Sponsors](https://github.com/sponsors/eddelbuettel).
