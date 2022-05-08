
## General

### Why is it called CRANapt?

We hope to eventually provide CRAN binaries for multiple distributions
(Debian, Ubuntu, ...), releases (testing/stable, LTS/current, ...), hardware
platforms, and so on.  But we have to start somewhere so Ubuntu LTS for amd64
is the first instance.

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

### What is the relationship with the c2d4u PPA ?

We are huge fans of the c2d4u repository and have used it for a decade or
longer. It uses the proper build process, and sits on a very solid Launchpad
infrastructure supported by Canonical.  However, this also makes it a little
less nimble and precludes for example use of external build resources.
Overall it also still at a fraction of CRAN packages. So we created this repo
as an experiment to see if we could scale a simple and direct approach, and
in the hopes it can complement the c2d4u PPA and offer additional packages


## bspm

### Should I install bspm?

We find it helpful. It allows you to use `install.packages()` in R, or script
`install.r`, and refer to _CRAN and BioConductor packages by their names_
which is more natural. `bspm` will call `apt` for you. Hence our default
Docker image has `bspm` installed and enabled by default.

### bspm is a little noisy

You can wrap `suppressMessages()` around `bspm::enable()`.  We now do so in
the Docker image.


## Other errors

### With the 22.04 "jammy" container I get errors

We found that adding `--security-opt seccomp=unconfined` to the `docker`
invocation silenced those on AWS hosts.  We did not seem to need them elsewhere.
