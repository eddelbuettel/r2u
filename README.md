
## r2u: CRAN as Ubuntu Binaries

### Key features

- **Full integration with `apt`** as every binary resolves _all_ its dependencies: No more
  installations (of pre-built archives) only to discover that a shared library is missing. No more
  surprises.

- **Full integration with `apt`** so that an update of a system library cannot break an R package:
  if a (shared) library is used by a CRAN, the package manager knows, and will not remove it.  No
  more (R package) breakage from (system) library updates.

- **Simpler and lighter** than some alternatives as only _run-time_ library packages are installed as
  dependencies (instead of generally heavier _development_ packages).

- **Installations are fast, automated and reversible** thanks to the package management layer.

- **Fast and well-connected mirror** at
  [r2u.stat.illinois.edu](https://r2u.stat.illinois.edu) on the [Internet2](https://internet2.edu/) 

- **Complete coverage** with (currently) ~ 20,000 CRAN packages (and 240+ from BioConductor).

- Complete support for both **Ubuntu 20.04** ("focal") **and Ubuntu 22.04** ("jammy").

- Optional (but recommended) [bspm](https://cloud.r-project.org/package=bspm) use
  **automagically connects R functions like `install.packages()` to `apt`** for access to binaries 
  _and_ dependencies.


### Brief Demo

The gif below shows how _one `install.packages("tidyverse")` command_ on an Ubuntu
20.04 system _installs all packages and dependencies as binaries in 18 seconds_ (by passing the
R package installation to `apt` using [bspm](https://cloud.r-project.org/package=bspm)).

![](https://eddelbuettel.github.io/r2u/assets/tidyverse_from_r2u_2022-05-04_17-09.gif)

This uses the Docker container referenced below, which has been set up with
the five easy setup steps detailed here.


### What is Covered ?

We generally support amd64 (_i.e._ standard Intel/AMD cpus) for the current Ubuntu LTS release and its
predecessor release.  We use 'r-release' just like CRAN. So currently the 'focal' 20.04 LTS and
'jammy' 22.04 LTS releases are fully supported.

Support for other cpu architectures is certainly possible but somewhat unlikely due to a lack of
(additional hardware) resources and time. Support for other distributions is possible but unlikely
right now (due to a lack of resources and time). We still hope to cover Debian at some point.

Current versions are R 4.2.2, and BioConductor release 3.16 packages are provided when required by
CRAN packages.


### What is Selected ?

Everything :)

Initially, we started from [cran-logs](https://cran-logs.rstudio.com/) by picking the _N_
most-downloaded packages, along with their dependencies from BioConductor.  (It should be noted that
for example the first 100 packages already account for approximately half the total downloads: it is
a very skewed distribution.) We iterated, and fairly soon arrived of full coverage of CRAN.

So we now cover

- *all CRAN packages* (modulo at best handful of blacklisted ones) including all packages needing
  compilation
- all BioConductor package that are implied by these (and build for us).

This currently resuls in 20727 and 20627 binary packages from CRAN in "focal" and "jammy",
respectively, and 249 and 245 BioConductor packages, respectively, from the 3.16 release.

The sole exception are two packages we cannot build (as we do not have the required commercial
software it accessess) plus less than a handful of 'odd builds' that fail and
are skipped.

### What is it Based On?

For the CRAN binaries we either repackage
[RSPM/PPM](https://packagemanager.rstudio.com/client/#/repos/2/packages/) builds (where available)
or build natively. All selected BioConductor 3.16 packages are built natively.  For all of these,
full dependency resolution and integration with the system is a key feature.

Everything is provided as `.deb` binary files with proper dependency
resolution by using a proper `apt` repo which also has a signed Release file.


### Usage and Setup

(Note that you could use one of the two scripts
[`add_cranapt_jammy.sh`](https://github.com/eddelbuettel/r2u/blob/master/inst/scripts/add_cranapt_jammy.sh)
(for Ubuntu 22.04), or
[`add_cranapt_focal.sh`](https://github.com/eddelbuettel/r2u/blob/master/inst/scripts/add_cranapt_focal.sh)
(for the older Ubuntu 20.04) to facilitate the setup. They are tested on 'empty' Ubuntu containers
of the corresponding release. However, you may prefer to execute the steps outlined here by hand.)

We show the setup step by step for 'jammy' aka Ubuntu 22.04. You should run all these commands
as `root` to carefully review each one.

#### Step 1: Update apt, install tools, fetch key  

First add the repository key so that `apt` knows it (this is optional but recommended)

    apt update -qq && apt install --yes --no-install-recommends wget ca-certificates gnupg
    wget -q -O- https://eddelbuettel.github.io/r2u/assets/dirk_eddelbuettel_key.asc \
        | tee -a /etc/apt/trusted.gpg.d/cranapt_key.asc


#### Step 2: Add the apt repo

Second, add the repository to the `apt` registry. We recommend the well-connected main mirror
provide at University of Illinois:

    echo "deb [arch=amd64] https://r2u.stat.illinois.edu/ubuntu jammy main" > /etc/apt/sources.list.d/cranapt.list
    apt update -qq

#### Step 3: Ensure you have current R binaries (optional)

Third, and optionally, if you do not yet have the current R version, run these two lines (or
use the [standard CRAN repo setup](https://cloud.r-project.org/bin/linux/ubuntu/))

    wget -q -O- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
        | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
    echo "deb [arch=amd64] https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/" > /etc/apt/ sources.list.d/cran_r.list
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 67C2D66C4B1D4339 51716619E084DAB9
    apt update -qq
    DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends r-base-core

#### Step 4: Use pinning for the r2u repo (optional)

Fourth, add repository 'pinning' as `apt` might get confused by some older
packages (in the Ubuntu distro) which accidentally appear with a higher
version number. See the next section for a short discussion how it ensures 'CRANapt' 
sorts highest.

    echo "Package: *" > /etc/apt/preferences.d/99cranapt
    echo "Pin: release o=CRAN-Apt Project" >> /etc/apt/preferences.d/99cranapt
    echo "Pin: release l=CRAN-Apt Packages" >> /etc/apt/preferences.d/99cranapt
    echo "Pin-Priority: 700"  >> /etc/apt/preferences.d/99cranapt

After that the package are known (under their `r-cran-*` and `r-bioc-*`
names).  You can install them on the command-line using `apt` and `apt-get`,
via `aptitude` as well as other front-ends.

#### Step 5: Use `bspm` (optional)

Fifth, and also optional, install and enable the [bspm](https://cloud.r-project.org/package=bspm)
package so that the r2u (or CRANapt) as well as other R packages (available as `r-*.deb` binaries)
become available via `install.packages()` and `update.packages()`. Note that you may need to install
it directly from source via `sudo Rscript -e 'install.packages("bspm")'` to ensure it integrates
correctly with the packaging system.  You should also install Python components used internally by
[bspm](https://cloud.r-project.org/package=bspm) via the `sudo apt-get install
python3-{dbus,gi,apt}` command.

    apt install --yes --no-install-recommends python3-{dbus,gi,apt}
    ## Then install bspm (as root) and enable it, and enable a speed optimization
    Rscript -e 'install.packages("bspm")'
    RHOME=$(R RHOME)
    echo "suppressMessages(bspm::enable())" >> ${RHOME}/etc/Rprofile.site
    echo "options(bspm.version.check=FALSE)" >> ${RHOME}/etc/Rprofile.site

That's it! Now try it out!


### About Pinning

Packages can be found in different repositories, and _generally_ the highest available version is
the one we what---and `apt` picks it for us. Now, because we let `apt` (and related tools) pick the
packages based on versions, we may want to ensure that the CRANapt repo sorts higher than the
default repo as (older) package builds in the distribution itself may appear (to `apt`) to be newer
via a quirk in the sorting algorithm. A case in point was package `gtable` whose version in Ubuntu
was `0.3.0+dfsg-1` which accidentally sorts higher than the rebuild we made under a newer and more
consistent version number `0.3.0-1.ca2004.1`.

For this issue, one possible and popular fix is to use 'apt pinning'. It can give 'higher weight'
to packages from a particular repositor or tag.  In the suggested example above, we
give the r2u / cranapt repo a weight of 700 which is higher than the package default value of
500.



### Docker

There are also two Docker containers for Ubuntu 20.04 'focal' and 22.04 'jammy', respectively, at
[eddelbuettel/r2u](https://hub.docker.com/repository/docker/eddelbuettel/r2u) that have the above,
including pinning and [bspm](https://cran.r-project.org/package=bspm) support, already set up.

Note that with some builds of Docker (and possibly related to Ubuntu hosts) you may have to add
the `--security-opt seccomp=unconfined` option to your Docker invocation to take advantage of bspm
and the full system integration inside the container.
This is also documented in the [FAQ](https://eddelbuettel.github.io/r2u/vignettes/FAQ/).



### Try It

Use this link below (after possibly signing up for
[gitpod.io](https://gitpod.io/) first)

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/eddelbuettel/r2u)

and run [one of the three example
scripts](https://github.com/eddelbuettel/r2u/tree/master/inst/examples), or
just start R in the terminal window.

![](https://eddelbuettel.github.io/r2u/assets/gitpod_brms_2022-05-08_11-21.gif)

The gif below display running one such example to install
[brms](https://github.com/paul-buerkner/brms) from binaries in a few seconds.  Using this requires
only (free) [GitHub](https://github.com) and [GitPod](https://gitpod.io) accounts.


### Support

Please file issues at the [GitHub issues for r2u](https://github.com/eddelbuettel/r2u/issues).


### Known Issues

- The littler package reflects build-time configuration, the RSPM binary is then expecting a
  different R location so it needs a binary rebuild. Added a 'force' flag, may need a list similar
  to the blacklist to always compiled.

- A small number of packages do not build for lack required components; examples are ROracle and
  Rcplex.  They, and their reverse dependencies, are blacklisted and not built.

- r2u is an `apt` repo, which via `bspm` becomes used "automagically" via standard R calls of
  `install.packages()` and alike. That last part is important: package installations that do not use
  `install.packages()` (such as `renv`, `rig`, ...) do not benefit from
  `install.packages()` calling `apt` for you, and cannot take advantage of r2u via `bspm`.
 
 - `bspm` traces calls to `install.packages()` and maps them system-wide installation via `apt`.  By
   choice, it does not map the `remove.packages()` for package removal, see [this
   issue](https://github.com/Enchufa2/bspm/issues/43) for more discussion. Packages can be uninstalled
   via the system package manager using, respectively, `apt`, `dpkg` or one of graphical frontends as
   well as via the R function `bspm::remove_sys()`.

### Author

Dirk Eddelbuettel

### License

The repository-building code in this package is released under the GPL (>= 2).

All CRAN and BioConductor packages are released under their respective licenses.

### Acknowledgment

This was made possible by the generous support of endless coffee thanks to my
[GitHub Sponsors](https://github.com/sponsors/eddelbuettel).
