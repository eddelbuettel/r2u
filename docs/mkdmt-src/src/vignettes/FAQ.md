
## General

### Why is it called both CRANapt and r2u?

We started out with the hope to eventually provide CRAN binaries for multiple
distributions (Debian, Ubuntu, ...), releases (testing/stable, LTS/current,
...), hardware platforms, and so on.  But we had to start somewhere, so
Ubuntu LTS for amd64 is the first instance. And as we are effectively only on
Ubuntu, at least for the time being, sp the shorter 'r2u' crept up, and stuck.

### How is it pronounced?

We think of the 'n' in CRANapt as silent so you can always say "oh I just
crapted these packages onto my system".

### A package reports that it is uninstallable

Make sure you follow the 'Pinnning' section of the README.md and the [setup
script](https://github.com/eddelbuettel/r2u/blob/master/inst/scripts/add_cranapt.sh).
Sometimes (older) builds in the (main) Ubuntu distribution appear to sort higher
and would block an installation of the freshly made binary (under a
consistent naming scheme). The `apt` feature of 'pinning' is what we want
here to have an entire repository sort higher.

There can also be other issues related to CRAN allowing a hyphen in version
(_e.g._ [nlme](https://cran.r-project.org/package=nlme) was at some point at
3.1-157. But Debian and Ubuntu use a hyphen to split off the build iteration
count so version numbers are sometimes standardised to for example 3.1.157
switching the hyphen to a dot. Sadly that leads to different sorting. (See
[issue #7](https://github.com/eddelbuettel/r2u/issues/7) for more on an issue
that was caused by this.)  In general we can not overcome this by pinning,
and we continue to try to find a more comprehensive solution that is less
invasive than changing many package version numbers.

### What is the relationship with the c2d4u PPA ?

tl;dr: r2u now replaces c2d4u.

We have been huge fans and supporters of the c2d4u repository and have used
it for a decade or longer. It used the proper build process, and sat on a
very solid Launchpad infrastructure supported by Canonical.  However, this
also made it a little less nimble and precluded for example use of external
build resources.  Overall it was always at a fraction of CRAN packages. So we
created this repo as an experiment to see if we could scale a simple and
direct approach, and in the hopes to complement the c2d4u PPA and offer
additional packages

As of 2024, that hope came to fruition: c2d4u is now taking a well-deserved
hiatus, and recommends switching to r2u instead. 

### How can one know when it was updated

We generally build multiple times per day now. But we currently have no 'lastBuilt' tag on the
website but could add one if that helped.  As builds are happening in public, you can always look at
the [builder repository](https://github.com/eddelbuettel/r2u-builder).


## Deployment

### Can I use (current) r2u with Debian?

In general, it is _not_ a good idea to mix packages from Debian and Ubuntu in the same
installation. The package management system works so well for either because it generally can rely
on proper package versions, dependencies, and relationships between packages. Mixing, while it may
work in small isolated cases, is really not suitable to such setups. So we recommend against using
(the current r2u setup which is Ubuntu-only) on Debian.  (This question was also asked in 
[issue #8](https://github.com/eddelbuettel/r2u/issues/8).)

### Can I use r2u with Ubuntu derivatives?

As long as the derivatives allow full use of Ubuntu repositories, they can be used with r2u as r2u
coexists nicely with Ubuntu. We have heard from several users doing this and it appears to 'just
work', we have not done so ourselves.

### Can I install Bioconductor packages from Ubuntu not in r2u

This used to be an issue in the earlier days. As of early 2024 and the BioConductor 3.18 release, we
also ensure we had all packages covered by the (originall Debian and hence also in the) Ubuntu
distribution. At that time, the distribution had around 170 packages whereas the set of packages
covered by r2u increased to by now around 600. With the combination of r2u generally having a newer
version along with the recommended pinning you should always get the r2u version without issues.

(And for historical context, back-then-when Ubuntu contained a number of Debian packages
`r-bioc-*`. However, as the distribution cutoff for the 'jammy' (22.04) cutoff was before
Bioconductor 3.15 was released so these packages had a dependency on the 'r-api-bioc-3.14' (virtual)
package. To satisfy this with our r2u packages, which were then based on the newer Bioconductor 3.15
(and later upgraded to 3.16, 3.17, now 3.18), we added a small [virtual package
`bioc-api-package`](https://github.com/eddelbuettel/bioc-api-package) that we added to the repo. So
after `sudo apt install bioc-api-package` installation of the addional Bioconductor packages in
jammy can proceed. For more details see 
[issue #11](https://github.com/eddelbuettel/r2u/issues/11). Note that none of what is described in this
second paragraph to the question is needed anymore given the changes described in the first. All
good!)

### Can I use it with other non-LTS Ubuntu releases?

Sure!  You can always forward-upgrade.  So for example the 22.04 ("jammy") release works perfectly
fine with 22.10 ("kinetic"). Just make sure you keep the `sources.list` entry on the LTS release you
have as we (just like many other repositories) only provide LTS releases and no interim releases.

The worst that can happen is that a particular (versioned) shared library is newer in the
newer-than-LTS release you run so you may have to either manually fetch and install it, or add the
LTS release along with your current Ubuntu to the `apt` `sources` directory.

When running 22.10 / 23.04 / 23.10 / 24.10 / 25.04 / 25.10 on a laptop with r2u, we are aware of one
binary for the [av](https://cloud.r-project.org/package=av) which ends up with a library dependency
no longer satisified by the distribution. So we built ourselves an ad-hoc new binary of `r-cran-av`
for the distro we ran. We will keep an eye on this to see if it affects other packages. If you find
one, please file an issue. We think we can (if need be) address this with a supplementary repo on an
'as-needed' basis. It may also help to keep the preceding LTS sources entry along with the newer
non-LTS entry.

### Why does it have more packages than CRAN ?

We (at least currently) do not purge packages from r2u that have been archived at CRAN.  Hence the
set of packages at r2u grows faster and further leading to a growing difference relative to CRAN.

### What about other architectures besides x86_64 ?

Excellent question. CRAN builds for at least three different OSs, Debian binaries are provided on
maybe 15 hardware platforms so 'how hard can it be?' you may ask (and some have in issues
[#40](https://github.com/eddelbuettel/r2u/issues/40) and
[#55](https://github.com/eddelbuettel/r2u/issues/55)).

Sadly, it can be quite hard. This is essentially somewhere between the third or fourth time I tried
to build something like this (some history is in [this paper](https://arxiv.org/abs/2103.08069)),
and it only got as (amazingly !)  far as it is has gotten because I could build on existing binaries
(later replaced by build under GitHub Actions).  None of that rich infrastructure exists for other
hardware platforms, and recall that all this also works by plugging into and relying on `apt` so it
would have to be a Debian (or Ubuntu) platform. 

But now, thanks to expanded support at GitHub Actions we also support arm64.  So starting with 24.04
both arm64 and amd64 are supported.

### Can one use `r2u` with Singularity containers?

Yes, as discussed [in this GitHub issue](https://github.com/eddelbuettel/r2u/issues/9).
The key is that Singularity does not allow `root` access, yet we need to install packages
via `bspm`.  The best answer is this to start from the base container, add packages as needed to
create a new Docker container -- and transfer / transform that container for Singularity use.

The running example in that issue is installing [Seurat](https://cloud.r-project.org/package=Seurat)
and moderately complex and extended dependencies. Thanks to how `r2u` is set up a simpler Dockerfile
such as

    FROM rocker/r2u:22.04
    RUN install.r Seurat

which by using `install.r` (from [littler](https://github.com/eddelbuettel/littler) along with
`bspm` turns this into a call to `apt`.  Call as, say, `docker build -t r2u_seurat:22.04 .`
and enjoy the resulting container `r2u_seurat:22.04` (or give it any other suitable name) and build
a suitable `.sif` from it as discussed in the issue.


## Usage 

### Why can I not uninstall packages with `remove.packages()` ?

This issue is known and documented, for example under [known issues in the main GitHub
README](https://github.com/eddelbuettel/r2u?tab=readme-ov-file#known-issues) shadowed in [the main
page of the documentation](https://eddelbuettel.github.io/r2u/#known-issues). The `bspm` package
traces `install.packages()` to facilitate installation; removal is a little more complicated as
[discussed in this issue at the `bspm` repo](https://github.com/Enchufa2/bspm/issues/43). However,
`bspm` provides a function `bspm::remove_sys()` to remove a package installed via r2u as a system
package.

Also see isues [#75](https://github.com/eddelbuettel/r2u/issues/75) and
[#35](https://github.com/eddelbuettel/r2u/issues/35).

### Can I install and use older versions by choice ?

Of course!  One key aspect of using R on Debian / Ubuntu is that the order the library path
directories (shown by calling `.libPaths()`) such that the system libraries come last. This means
that you can always call `bspm::disable(); install.packages("some_package")` to install
`some_package` into either your personal repository within `$HOME` or into
`/usr/local/lib/R/site-packages/`.  Just make sure to disable `bspm` to be able to install
'normally' from source. 

See issue [#75](https://github.com/eddelbuettel/r2u/issues/75) where this is discussed a little too
and an example is provided.

### Should I install bspm?

We find it helpful. It allows you to use `install.packages()` in R, or script `install.r`, and refer
to _CRAN and BioConductor packages by their names_ which is more natural. `bspm` will call `apt` for
you. Hence our default Docker image has `bspm` installed and enabled by default.

(Also see below though for `docker build` and `bspm`.)

### bspm is a little noisy

You can wrap `suppressMessages()` around `bspm::enable()`.  We now do so in the Docker image.

### With the 22.04 "jammy" container I get 'Cannot connect' errors

We found that adding `--security-opt seccomp=unconfined` to the `docker` invocation silenced those
on AWS hosts and possibly other systems.  This may be related to Ubuntu hosts only.

A side-effect of this required security policy statement for `bspm` is that `bspm` is not available
when building containers off `r2u`.  It appears that Docker rules this out during builds.  The only
remedy is to use `bspm::disable()` and to rely on just `apt` to install the `r2u` packages in
derived containers.

