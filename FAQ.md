
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

Make sure you follow the 'Pinnning' section of the README.md.  Some (older)
builds in the (main) Ubuntu distribution appear to sort higher and would
block an installation of the freshly made binary (under a consistent naming
scheme). The `apt` feature of 'pinning' is what we want here to have an
entire repository sort higher.

## bspm

### Should I install bspm?

We find it helpful. It allows you to use `install.packages()` in R, or script
`install.r`, and refer to _CRAN and BioConductor packages by their names_
which is more natural. `bspm` will call `apt` for you. Hence our default
Docker image has `bspm` installed and enabled by default.

### bspm is a little noisy

You can wrap `suppressMessages()` around `bspm::enable()`.  We now do so in
the Docker image.
