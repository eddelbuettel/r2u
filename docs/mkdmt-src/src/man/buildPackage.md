
## Build a Package

### Description

Builds a package considering the repository information, dependencies
and already built packages.

### Usage

``` R
buildPackage(pkg, db, repo = c("CRAN", "Bioc"), debug = FALSE,
  verbose = FALSE, force = FALSE, xvfb = FALSE, suffix = ".1")

buildAll(pkg, db, repo = c("CRAN", "Bioc"), debug = FALSE)

topN(npkg, date = Sys.Date() - 1, from = 1L)

topNCompiled(npkg, db, date = Sys.Date() - 1, from = 1L)
```

### Arguments

|           |                                                                                         |
|-----------|-----------------------------------------------------------------------------------------|
| `pkg`     | character Name of the CRAN or BioConductor package to build                             |
| `db`      | data.frame Optional repository information now taken from information loaded at startup |
| `repo`    | character Optional value either ‘CRAN’ or ‘Bioc’ now also in `db` loaded                |
| `debug`   | logical Optional value to show more debugging output, default is ‘FALSE’                |
| `verbose` | logical Optional value show more verbose progress output, default is ‘FALSE’            |
| `force`   | logical Optional value to force package build from source, default is ‘FALSE’           |
| `xvfb`    | logical Optional value to build under `xvfb-run`, default is ‘FALSE’                    |
| `suffix`  | character Optional value to override default of ‘.1’ affixed to package version         |
| `npkg`    | integer Number of packages to build                                                     |
| `date`    | Date Relevant date for cranlog download stats                                           |
| `from`    | integer Optional applied as offset to `npkg` to shift the selection                     |

### Details

The `buildPackage` function builds the given package. The `buildAll`
package applies to all elements in the supplied vector of packages. The
`topN` and `topNCompiled` helpers select ‘N’ among all (or all compiled)
packages.

### Value

Nothing as the function is invoked for the side effect of building
binary packages

### Author(s)

Dirk Eddelbuettel

