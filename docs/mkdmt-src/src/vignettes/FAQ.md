
## General

### Why is it called both CRANapt and r2u?

We hope to eventually provide CRAN binaries for multiple distributions
(Debian, Ubuntu, ...), releases (testing/stable, LTS/current, ...), hardware
platforms, and so on.  But we had to start somewhere, so Ubuntu LTS for amd64
is the first instance. And as we are effectively only on Ubuntu for now, the
shorter 'r2u' crept up, and stuck.

### How is it pronounced?

We think of the 'n' as silent so you can always say "oh I just crapted these
packages onto my system".

### A package reports it is uninstallable

Make sure you follow the 'Pinnning' section of the README.md and the [setup
script](https://github.com/eddelbuettel/r2u/blob/master/inst/scripts/add_cranapt.sh).
Some (older) builds in the (main) Ubuntu distribution appear to sort higher
and would block an installation of the freshly made binary (under a
consistent naming scheme). The `apt` feature of 'pinning' is what we want
here to have an entire repository sort higher.

There can also be other issues related to CRAN allowing a hyphen in version
(_e.g._ [nlme](https://cran.r-project.org/package=nlme) is currently at
3.1-157. But Debian and Ubuntu use a hyphen to split off the build iteration
count so version numbers are sometimes standardised to for example 3.1.157
switching the hyphen to a dot. Sadly that leads to different sorting. (See
[issue #7](https://github.com/eddelbuettel/r2u/issues/7) for more on an issue
that was caused by this.)  In general we can not overcome this by pinning,
and we continue to try to find a more comprehensive solution that is less
invasive than changing many package version numbers.

### What is the relationship with the c2d4u PPA ?

We are huge fans of the c2d4u repository and have used it for a decade or
longer. It uses the proper build process, and sits on a very solid Launchpad
infrastructure supported by Canonical.  However, this also makes it a little
less nimble and precludes for example use of external build resources.
Overall it also still at a fraction of CRAN packages. So we created this repo
as an experiment to see if we could scale a simple and direct approach, and
in the hopes it can complement the c2d4u PPA and offer additional packages

### Can I use (current) r2u with Debian?

In general, it is _not_ a good idea to mix packages from Debian and Ubuntu in
the same installation. The package management system works so well for either
because it generally can rely on proper package versions, dependencies, and
relationships between packages. Mixing, while it may work in small isolated
cases, is really not suitable to such setups. So we recommend against using
(the current r2u setup which is Ubuntu-only) on Debian.  (This question was
also asked in [issue #8](https://github.com/eddelbuettel/r2u/issues/8).)

### Can I install Bioconductor packages from Ubuntu not in r2u

Ubuntu contains a number of Debian packages `r-bioc-*`. However, the
distribution cutoff for the 'jammy' (22.04) cutoff was before Bioconductor 3.15
was released so these packages have a dependency on the 'r-api-bioc-3.14'
(virtual) package. To satisfy this with our r2u packages, which are based on
the newer Bioconductor 3.15, we added a small [virtual package
`bioc-api-package`](https://github.com/eddelbuettel/bioc-api-package) that we
added to the repo. So after `sudo apt install bioc-api-package` installation of
the addional Bioconductor packages in jammy can proceed. For more details see 
[issue #11](https://github.com/eddelbuettel/r2u/issues/11). 

### Can I use it with other non-LTS Ubuntu releases?

Of course!  You can always forward-upgrade.  So for example the 22.04
("jammy") release works perfectly fine with 22.10 ("kinetic"). Just make sure
you keep the `sources.list` entry on the LTS release you have as we (just
like many other repositories) only provide LTS releases and no interim
releases. 


## bspm

### Should I install bspm?

We find it helpful. It allows you to use `install.packages()` in R, or script
`install.r`, and refer to _CRAN and BioConductor packages by their names_
which is more natural. `bspm` will call `apt` for you. Hence our default
Docker image has `bspm` installed and enabled by default.

(Also see below though for `docker build` and `bspm`.)

### bspm is a little noisy

You can wrap `suppressMessages()` around `bspm::enable()`.  We now do so in
the Docker image.


## 'Cannot connect' errors

### With the 22.04 "jammy" container I get errors

We found that adding `--security-opt seccomp=unconfined` to the `docker`
invocation silenced those on AWS hosts and possibly other systems. 
This may be related to Ubuntu hosts only.

A side-effect of this required security policy statement for `bspm` is that
`bspm` is not available when building containers off `r2u`. 
It appears that Docker rules this out during builds.
The only remedy is to use `bspm::disable()` and to rely on just `apt` to
install the `r2u` packages in derived containers.

## Can one use `r2u` with Singularity containers?

Yes, as discussed [in this GitHub issue](https://github.com/eddelbuettel/r2u/issues/9).
The key is that Singularity does not allow `root` access, yet we need to install packages
via `bspm`.  The best answer is this to start from the base container, add packages as needed to
create a new Docker container -- and transfer / transform that container for Singularity use.

The running example in that issue is installing [Seurat](https://cloud.r-project.org/package=Seurat)
and moderately complex and extended dependencies. Thanks to how `r2u` is set up a simpler Dockerfile
such as

    FROM eddelbuettel/r2u:22.04
    RUN install.r Seurat

which by using `install.r` (from [littler](https://github.com/eddelbuettel/littler) along with
`bspm` turns this into a call to `apt`.  Call as, say, `docker build -t r2u_seurat:22.04 .`
and enjoy the resulting container `r2u_seurat:22.04` (or give it any other suitable name) and build
a suitable `.sif` from it as discussed in the issue.


## How can one know when it was updated

We follow RSPM builds so their [update tracker](https://packagemanager.rstudio.com/client/#/repos/1/activity)
there can be helpful. We currently have no 'lastBuilt' tag on the website but could add one if that helped.
