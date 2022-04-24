
## r2u:  R Binaries for Ubuntu

Key features:

- **Full integration with `apt`** as every binary resolves _all_ dependencies: No
  more installations (of pre-built archives) only to discover that a shared
  library is missing. No more surprises.

- **Full integration with `apt`** so that an update of a system library
  cannot break an R package: if a (shared) library is used by a CRAN, the
  package manager knows and will not remove it.  No more `libicu*` update
  breaking `stringi`.
  
- Installations are fast and automatic


### What is Covered ?

We currently support amd64 (_i.e._ standard Intel/AMD cpus) for the _focal_
20.04 LTS release.  An update to 22.04 is planned.

Support for other cpu architectures is possible but unlikely (due to a lack
of resources and time).

Support for other distributions is possible but unlikely right now (due to a lack
of resources and time).

### What is Selected ?

We use [cran-logs](https://cran-logs.rstudio.com/) and pick the _N_
most-downloaded package, along with their dependencies from BioConductor.

It should be noted that the first 100 packages account for approximately half
the total downloads.

In a first stage, we aim to cover all approximately 4500 binary CRAN packages
and about fifty per cent of all packages.


### Author

Dirk Eddelbuettel


### License

All CRAN packages are released under their respective licenses.
