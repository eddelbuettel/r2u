
## downloader from RSPM
.get_package_file <- function(pkg, ver) {
    cachedir <- file.path(.getConfig("package_cache"), .getConfig("distribution_name"))
    if (!dir.exists(cachedir)) dir.create(cachedir, recursive=TRUE)
    path <- file.path(cachedir, paste0(pkg, "_", ver, ".tar.gz"))
    if (!file.exists(path)) {
        ppmrepo <- paste0("https://packagemanager.posit.co/all/__linux__/", .getConfig("distribution_name"), "/latest")
        #cranrepo <- "https://cloud.r-project.org"
        #repo <- if (nzchar(Sys.getenv("CI", ""))) ppmrepo else cranrepo
        repo <- ppmrepo
        rv <- R.version
        ## agent <- sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), rv$platform, rv$arch, rv$os))
        rversion <- .getConfig("minimum_r_version")  # e.g. "4.2.2"
        agent <- sprintf("R/%s R (%s)", rversion, paste(rversion, rv$platform, rv$arch, rv$os))
        options(HTTPUserAgent = agent)
        download.packages(pkg, cachedir, repos = repo, quiet = TRUE)
        cat(green("[downloaded] "))
    } else {
        cat(green("[cached] "))
    }
    path
}

## downloader from bioc
.get_source_file <- function(pkg, ver, ap, force) {
    cachedir <- file.path(.getConfig("package_cache"), .getConfig("distribution_name"))
    if (!dir.exists(cachedir)) dir.create(cachedir, recursive=TRUE)
    path <- file.path(cachedir, paste0(pkg, "_", ver, ".tar.gz"))
    if (!file.exists(path) || force) {
        remotefile <- file.path(repos=ap[,Repository], paste0(pkg, "_", ver, ".tar.gz"))
        download.file(remotefile, destfile=path, quiet=TRUE)
        cat(green("[downloaded] "))
    } else {
        cat(green("[cached] "))
    }
    path
}

.filterAndMapPackage <- function(p, AP) {
    if (.isBasePackage(p))
        return("")
    n <- match(p, AP$Package)
    if (!is.finite(n)) {
        cat(red("Unknown: ", p))
        return("")
    }

    ap <- AP[n, ]
    if (!is.na(ap$Priority) && (ap$Priority == "recommended"))
        return("")

    ap$deb
}

.filterAndMapBuildDepends <- function(pkg, ap) {
    pkgvec <- tools::package_dependencies(pkg, db=ap, recursive=TRUE)[[1]]
    res <- sapply(pkgvec, .filterAndMapPackage, ap, USE.NAMES=FALSE)
    res <- Filter(Negate(function(x) x==""), res)
    if (length(res) > 0) res <- sort(res)
    res
}

##' Builds a package considering the repository information, dependencies and already
##' built packages.
##'
##' The \code{buildPackage} function builds the given package. The \code{buildAll} package applies
##' to all elements in the supplied vector of packages. The \code{topN} and \code{topNCompiled} helpers
##' select \sQuote{N} among all (or all compiled) packages. The \code{nDeps} function builds packages
##' with a given (adjusted) build-dependency count. The \code{buildUpdatedPackages} function finds a 
##' set of available packages that are not yet built.
##'
##' Note that this build process is still somewhat tailored to the build setup use by the author and
##' is not (yet ?) meant to be universally transferable. It should be with a little care and possible
##' examination of the code. If interested, please get in touch.
##'
##' @title Build a Package
##' @param pkg character Name of the CRAN or BioConductor package to build
##' @param tgt character Name (or version) of the build target distribution, this is restricted
##' to either \dQuote{20.04}, \dQuote{22.04} or \dQuote{24.04} (or their names \dQuote{focal},
##' \dQuote{jammy} or \dQuote{noble}_
##' @param debug logical Optional value to show more debugging output, default is \sQuote{FALSE}
##' @param verbose logical Optional value show more verbose progress output, default is \sQuote{FALSE}
##' @param force logical Optional value to force package build from source, default is \sQuote{FALSE}
##' @param xvfb logical Optional value to build under \code{xvfb-run}, default is \sQuote{FALSE}
##' @param suffix character Optional value to override default package version suffix of \sQuote{.1}
##' @param debver character Optional value for beginning of Debian build version,
##' default \sQuote{1.}
##' @param plusdfsg logical Optional switch whether \dQuote{+dfsg} gets appended to usptream,
##' default \sQuote{FALSE}
##' @param dryrun logical Optional value to skip actual package build step, default is \sQuote{FALSE}
##' @param compile logical Optional value to ensure compilation from source, default is \sQuote{FALSE}
##' @param bioc logical Optional switch for BioConductor build
##' @return Nothing as the function is invoked for the side effect of building binary packages
##' @seealso \code{buildUpdatedPackages}
##' @author Dirk Eddelbuettel
buildPackage <- function(pkg, tgt, debug=FALSE, verbose=FALSE, force=FALSE, xvfb=FALSE,
                         suffix=".1", debver="1.", plusdfsg=FALSE, dryrun=FALSE, compile=FALSE) {
    db <- .pkgenv[["db"]]
    stopifnot("db must be data.frame" = inherits(db, "data.frame"))
    .checkTarget(tgt)
    .loadBuilds(tgt)        		# local or remote
    .addBuildDepends(tgt)               # add distro-release versioned depends
    .addBlacklist(tgt)                  # add distro-release blacklist
    .addBlacklist(.platform())          # add arch blacklist (for arm64)
    .addRuntimedepends(tgt)             # add distro-release run-time depends
    if (.isBasePackage(pkg)) return(invisible())
    ind <- match(pkg, db[,Package])
    ap <- .pkgenv[["ap"]]
    aind <- match(pkg, ap[,Package])
    if (is.na(ind) && is.na(aind)) {
        if (verbose) message(paste0("Package '", pkg, "' not known to current CRAN package database."))
        return(invisible())
    }
    tgtdist <- gsub("\\.", "", .pkgenv[["distribution"]])   ## NB this will not work for Debian testing

    builds <- .pkgenv[["builds"]][tgt == tgtdist,]

    repo <- ap[aind, ap]
    if (is.na(repo) || is.na(match(repo, c("CRAN", "Bioc")))) {
        if (verbose) message("skipping ", pkg, " as unknown")
        return(invisible())
    }
    repol <- tolower(repo)

    ## todo: check license and all that
    D <- db[ind,]
    AP <- ap[aind,]
    #if (debug) if (repo == "CRAN") print(D) else print(AP)
    ver <- D[, Version]
    aver <- AP[, Version]

    ## accomodate 'dash-to-dot' version change in Debian for some old 'recommended' packages
    if (pkg %in% c("nlme", "foreign")) {
        ver <- gsub("-", ".", ver)
        aver <- gsub("-", ".", aver)
    }

    effrepo <- AP[, ap]
    if (is.na(effrepo)) {
        cat(pkg, "missing, skipping\n")
        return(invisible())
    }
    if (effrepo == "Bioc") ver <- aver 		# BioC pkgs in CRAN db so carry version over
    pkgname <- paste0("r-", tolower(effrepo), "-", tolower(pkg)) 			# aka r-cran-namehere
    cand <- paste0(pkgname, "_", ver)
    if (effrepo == "CRAN" && isFALSE(ver == aver) && isFALSE(force)) {
        if (verbose) cat(blue(sprintf("%-22s %-11s %-11s", pkg, ver, aver))) 		# start console log with pkg
        if (verbose) cat("[not yet available - skipping]\n")
        return(invisible())
    } else if (effrepo == "Bioc") {
        if (is.finite(match(cand, builds[, pkgver])) && isFALSE(force)) { 		# if already built
            if (verbose) {
                cat(blue(sprintf("%-22s %-11s %-11s", pkg, ver, aver)))
                cat(green("[already built - skipping]\n"))
            }
            return(invisible())         						# exit
        }
    } else {
        ver <- aver
    }
    pkgname <- paste0("r-", tolower(effrepo), "-", tolower(pkg)) 			# aka r-cran-namehere
    cand <- paste0(pkgname, "_", ver)
    if (!is.null(builds) && is.finite(match(cand, builds[, pkgver])) && isFALSE(force) && suffix==".1") {
        if (verbose) cat(blue(sprintf("%-22s %-11s %-11s", pkg, aver, ver))) 		# start console log with pkg
        if (verbose) cat(green("[already built - skipping]\n"))
        return(invisible())
    }

    ## side-effect of the Breaks for R 4.3.1 and the newly built packages
    ## no longer needed as of R 4.4.2 in Feb 2025
    #if (  (pkg == "magick"     && ver == "2.7.4")
    #    ||(pkg == "MALDIquant" && ver == "1.22.1")
    #    ||(pkg == "ps"         && ver == "1.7.5")
    #    ||(pkg == "ragg"       && ver == "1.2.5")
    #    ||(pkg == "svglite"    && ver == "2.1.1")
    #    ||(pkg == "tibble"     && ver == "3.2.1")) {
    #    if (verbose) {
    #        cat(blue(sprintf("%-22s %-11s %-11s", pkg, ver, aver)))
    #        cat(red("[silly breaks side effect, skipping]\n"))
    #    }
    #    return(invisible())
    #}

    ## so we're building one
    cat(blue(sprintf("%-22s %-11s %-11s", pkg, ver, aver))) 		# start console log with pkg
    if (is.finite(match(pkg, .pkgenv[["blacklist"]]))) {
        cat(red("[blacklisted, skipping]\n"))
        return(invisible())
    }

    if (repo == "CRAN" && is.na(match(pkg, db[,Package]))) {
        cat("[skipping as not in current CRAN db]\n")
        return(invisible())
    }

    cat(green(sprintf("[%4s] ", tolower(effrepo))))
    file <- if (repo == "CRAN" && isFALSE(force) && isFALSE(compile)) {
                cat(green("[bin] "))
                .get_package_file(pkg, D[, Version]) 			# rspm file, possibly cached
            } else {
                cat(green("[src] "))
                .get_source_file(AP[, Package], AP[, Version], AP, isTRUE(force) && isTRUE(compile))
            }

    build_dir <- .getConfig("build_directory")
    if (!dir.exists(build_dir)) {
        stop("Build directory '", build_dir, "' does not exist")
        dir.create(build_dir, recursive=TRUE)
    }
    build_dir <- file.path(build_dir, .getConfig("distribution_name"))
    if (!dir.exists(build_dir)) dir.create(build_dir, recursive=TRUE)
    setwd(build_dir)

    if (!dir.exists(pkg)) dir.create(pkg) 				# name here inside build
    setwd(pkg)

    instdir <- file.path("debian", pkgname, "usr", "lib", "R", "site-library") 	# unpackaged binary
    if (!dir.exists(instdir)) dir.create(instdir, recursive=TRUE)

    if (repo == "CRAN" && isFALSE(force)) {
        untar(file, exdir=instdir)
        if (!file.exists(file.path(instdir, pkg, "Meta", "package.rds"))) {
            cat("[forcing source build]\n")
            buildPackage(pkg, tgt, debug, version, force=TRUE, xvfb, suffix,
                         debver, plusdfsg, dryrun, compile)
            return(invisible())
        }
    } else {
        if (!dir.exists("src")) dir.create("src")
        untar(file, exdir="src")
    }

    setwd("debian")

    .writeControl(pkg, db, ap, repo)
    .writeChangelog(pkg, db, ap, repo, suffix=suffix, debver=debver, plusdfsg=plusdfsg)
    .writeRules(pkg, repo)
    .writeCopyright(pkg, D[, License])
    .writeSourceFormat(pkg)
    r2u_dir <- .getConfig("r2u_directory")
    setwd(r2u_dir)
    distname <- .getConfig("distribution_name")
    build_container <- .getConfig("build_container")
    container <- paste0(build_container, ":", distname)
    deps <- if (pkg %in% names(.getConfig("builddeps"))) .getConfig("builddeps")[pkg] else ""
    added_deps <- if (repo == "Bioc" || isTRUE(force)) paste(.filterAndMapBuildDepends(pkg, ap), collapse=" ") else ""
    depstr <- if (nchar(deps) + nchar(added_deps) > 0) paste0("-a '", deps, " ", added_deps, "' ") else " "
    if (.in.docker()) {
        chkdir <- file.path(.getConfig("build_directory"), .getConfig("distribution_name"), pkg)
        if (!dir.exists(chkdir)) dir.create(chkdir, recursive=TRUE) 				
        cmd <- paste0("debBuild.sh ",
                      if (isTRUE(xvfb) || grepl("(tcltk|tkrplot)", depstr)) "-x " else " ",
                      if (repo == "Bioc") "-b " else " ",
                      if (repo == "Bioc" || isTRUE(force)) "-s " else " ",
                      "-d ", distname, " ",
                      depstr,
                      pkg)
    } else {
        cmd <- paste0("docker run --rm -ti ",
                      "-v ", getwd(), ":/mnt ",
                      "-w /mnt/build/", distname, "/", pkg, " ",
                      container, " debBuild.sh -r /mnt ",
                      if (isTRUE(xvfb) || grepl("(tcltk|tkrplot)", depstr)) "-x " else " ",
                      if (repo == "Bioc") "-b " else " ",
                      if (repo == "Bioc" || isTRUE(force)) "-s " else " ",
                      "-d ", distname, " ",
                      depstr,
                      pkg)
    }
    if (debug) print(cmd)
    if (dryrun) {
        cat(blue("[dry-run so not building]\n"))
        if (verbose) cat("CMD: ", cmd, "\n")
    } else {
        rc <- system(cmd, ignore.stdout=!debug)
        if (rc == 0) cat(green("[built]\n")) else cat(red("[error ", rc, "]\n",sep=""))
    }
    invisible()
}

#' @rdname buildPackage
buildAll <- function(pkg, tgt, debug=FALSE, verbose=FALSE, force=FALSE, xvfb=FALSE) {
    db <- .pkgenv[["db"]]
    stopifnot("db must be data.frame" = inherits(db, "data.frame"))
    .checkTarget(tgt)
    deps <- tools::package_dependencies(pkg, db=db, recursive=TRUE)
    vec <- unique(sort(c(pkg, unname(do.call(c, deps)))))
    ignoredres <- sapply(vec, buildPackage, tgt, debug, verbose, force, xvfb)
    invisible()
}

.getCachedDLLogsFile <- function(date=Sys.Date() - 1) {
    cachedir <- .getConfig("package_cache")
    if (!dir.exists(cachedir)) dir.create(cachedir, recursive=TRUE)
    cachedfile <- file.path(cachedir, strftime(date, "cranlogs-%Y-%m-%d.csv.gz"))
    if (!file.exists(cachedfile)) {
        url <- strftime(date, "http://cran-logs.rstudio.com/%Y/%Y-%m-%d.csv.gz")
        download.file(url, cachedfile, quiet=TRUE)
    }
    cachedfile
}

#' @rdname buildPackage
#' @param npkg integer Number of packages to build
#' @param date Date Relevant date for cranlog download stats
#' @param from integer Optional applied as offset to \code{npkg} to shift the selection
topN <- function(npkg, date=Sys.Date() - 1, from=1L) {
    D <- .local_fread(.getCachedDLLogsFile(date))
    D <- D[, .N, keyby=package][order(N,decreasing=TRUE)]
    D[seq(from, min(from+npkg-1L, nrow(D))),package]
}

#' @rdname buildPackage
topNCompiled <- function(npkg, date=Sys.Date() - 1, from=1L) {
    db <- .pkgenv[["db"]]
    D <- .local_fread(.getCachedDLLogsFile(date))
    DN <- D[, .N, keyby=package][order(N,decreasing=TRUE)]
    setnames(DN, "package", "Package")
    CP <- db[NeedsCompilation != "no", Package]
    DN <- DN[CP, on="Package"][order(N, decreasing=TRUE)]
    DN[seq(from, min(from+npkg-1L, nrow(DN))),Package]
}

.deb2pkg <- function(debpkgname, verbose=FALSE) {
    ap <- db <- .pkgenv[["ap"]]
    pkg <- ap[deb==debpkgname,Package]
    if (verbose) cat(blue("[", pkg,"] ", sep=""))
    pkg
}

#  no longer in rd ' @rdname buildPackage
.nDeps <- function(ndeps) {
    db <- .pkgenv[["db"]]
    db[adjdep == ndeps, Package]
}

#  no longer in rd ' @rdname buildPackage
.nDepsRange <- function(ndepslo, ndepshi) {
    db <- .pkgenv[["db"]]
    db[adjdep >= ndepslo & adjdep <= ndepshi, Package]
}

.getUpdatedPackages <- function(tgt) {
    .checkTarget(tgt)

    ## get available packages (which is updated on package load if older than cache age)
    ap <- .pkgenv[["ap"]]
    ap[, pkgver := paste(deb, Version, sep="_"), by=deb]

    ## update list of builds for chosen target distribution and access
    .loadBuilds(tgt)
    bb <- .pkgenv[["builds"]]

    ## find new available package_version pairs (from CRAN) that not yet built (ie in bb)
    newpkgs <- setdiff(ap[ap=="CRAN",pkgver], bb[,pkgver])

    ## get vector of packages to build
    pkgs <- ap[newpkgs, Package, on="pkgver"]

    ## and diff against the blacklist
    pkgs <- setdiff(pkgs, .pkgenv[["blacklist"]])
}

.getUpdatedBiocPackages <- function(tgt) {
    ## modeled after .getUpdatedPackages above, but adjusting for the fact that
    ## our universe of 'relevant BioC packages' to compare to is much smaller

    .checkTarget(tgt)

    ## get available packages (which is updated on package load if older than cache age)
    ap <- .pkgenv[["ap"]]
    ap <- ap[ap == "Bioc", pkgver := paste(deb, Version, sep="_"), by=deb]
    ap <- ap[, pkg := tolower(Package)]

    ## update list of builds for chosen target distribution and access
    .loadBuilds(tgt)
    bb <- .pkgenv[["builds"]][grepl("^r-bioc", name),]
    bb <- bb[, pkg := gsub("r-bioc-(.*)_.*", "\\1", pkgver)]

    ap <- ap[bb, on="pkg"]
    ap <- ap[, i.pkgver := NULL]

    newpkgs <- setdiff(ap[is.na(pkgver)==FALSE, pkgver], bb[, pkgver])
    #pkgs <- ap[newpkgs,,on="pkgver"]
    #print(pkgs)

    ## get vector of packages to build
    pkgs <- ap[newpkgs, Package, on="pkgver"]

    ## and diff against the blacklist
    pkgs <- setdiff(pkgs, .pkgenv[["blacklist"]])
}

#' @rdname buildPackage
buildUpdatedPackages <- function(tgt, debug=FALSE, verbose=FALSE, force=FALSE, xvfb=FALSE, bioc=FALSE, dryrun=FALSE) {
    .addBlacklist(tgt)             		# add distro blacklist
    pkgs <- if (bioc) .getUpdatedBiocPackages(tgt) else .getUpdatedPackages(tgt)
    pkgs <- pkgs[order(tolower(pkgs))]
    if (dryrun) print(pkgs) else buildAll(pkgs, tgt, debug=debug, verbose=verbose, force=force, xvfb=xvfb)
}

# no longer in rd @rdname buildPackage
.toTargets <- function(pkgs, filename="") {
    ## this version is used for amd64 where the stdout is redirected
    ##
    ## this corresponds to the `jq` based snippet to turn a vector of packages into a JSON expression
    ## which is suitable as input to a GitHub Actions 'matrix' to control parallel work
    ## ie
    ## > vec
    ## [1] "microbenchmark" "parallelly"     "bitops"         "matrixStats"
    ## > toTargets(vec)
    ## {"target":["microbenchmark","parallelly","bitops","matrixStats"]}
    ## >
    cat('{"target":[', sep="", file=filename)
    lastpkgs <- tail(pkgs,1)
    for (p in pkgs) {
        cat('"', p, '"', sep="", file=filename, append=TRUE)
        if (p != lastpkgs) cat(',', sep="", file=filename, append=TRUE)
    }
    cat("]}\n", file=filename, append=TRUE)
}

# no longer in rd @rdname buildPackage
.toTargetsString <- function(pkgs) {
    ## like preceding function but returns a string
    txt <- '{"target":['
    lastpkgs <- tail(pkgs,1)
    for (p in pkgs) {
        txt <- paste0(txt, '"', p, '"')
        if (p != lastpkgs) txt <- paste0(txt, ',')
    }
    txt <- paste0(txt, "]}")
}

# no longer in rd @rdname buildPackage
.toTargetsArrayString <- function(pkgs) {
    ## this is used for bioc where we do not pretend the '{"targets":' bit (and final '}')
    ## this corresponds to the `jq` based snippet to turn a vector of packages into a JSON expression
    ## which is suitable as input to a GitHub Actions 'matrix' to control parallel work
    ## ie
    ## > vec
    ## [1] "microbenchmark" "parallelly"     "bitops"         "matrixStats"
    ## > toTargets(vec)
    ## ["microbenchmark","parallelly","bitops","matrixStats"]
    ## >
    txt <- '['
    lastpkgs <- tail(pkgs,1)
    for (p in pkgs) {
        txt <- paste0(txt, '"', p, '"')
        if (p != lastpkgs) txt <- paste0(txt, ',')
    }
    txt <- paste0(txt, "]")
}

.toSerializedArrayString <- function(pkgs) {
    rawToChar(serialize(.toTargetsArrayString(pkgs), connection=NULL, ascii=TRUE))
}

.toCollapsedPackageString <- function(pkgs) {
    #paste0(paste0(sapply(pkgs, \(x) paste0("\"", x, "\""))), collapse=",")
    paste(pkgs, collapse=",")
}

.triggerBiocBuild <- function(pkgs, dist) {
    url <- "https://api.github.com/repos/eddelbuettel/r2u-bioc-builder/actions/workflows/158741339/dispatches"
    #rawtxt <- gsub("\\", "\\\\", .toSerializedArrayString(pkgs))
    txt <- .toCollapsedPackageString(pkgs)
    body <- paste0('{"ref":"main","inputs":{"targets":"', txt, '","dist":"', dist, '"}}')
    cat("Preparing", length(pkgs), "pkgs:", txt, "on", dist)
    #return(invisible(NULL))
    response <- httr::POST(url = url, config = httr::add_headers(Accept = "application/vnd.github+json", Authorization = paste("Bearer", Sys.getenv("GITHUB_PAT"))), body = body)
    text <- httr::content(response, "text", encoding = "UTF-8")
    if (text != "") cat(text, "\n")
    cat(" [triggered]\n")
    invisible(NULL)
}

# To not require R.utils for reading a compressed gz
## .local_fread <- function(url) {
##     tf <- tempfile(fileext="csv.gz")
##     download.file(url, tf, quiet=TRUE)
##     res <- data.table::fread(tf)
##     unlink(tf)
##     res
## }
.local_fread <- function(fname) {
    cmd <- paste("zcat", fname)
    res <- data.table::fread(cmd=cmd)
    res
}

## ## Helper function for GitHub Actions builds
## # ' @ rdname buildPackage
## getBuildTargets <- function(filename, N=200, verbose=TRUE) {
##     if (requireNamespace("RcppAPT", quietly=TRUE)) {
##         ## get packages already Built
##         B <- data.table(RcppAPT::getPackages("^r-(bioc|cran)-"), key="Package")
##         ##B[, tgt := gsub(".*-\\d+.ca(\\d{4}).\\d+.*", "\\1", Version), by=Package]
##         B[, r2u := grepl("ca2404", Version), by=Package]
##         B[, vv := gsub("^\\d:", "", Version), by=Package]
##         B[, vvv := gsub("-\\d$", "", vv), by=Package]
##         B[, vvvv := gsub("-\\d\\.ca\\d{4}\\.\\d$", "", vvv), by=Package]
##         B[, pkgver := paste(Package, vvvv, sep="_")]
##         B[, let(vv = NULL, vvv = NULL, vvvv = NULL) ]

##         ## get target package, here top N compiled
##         topN <- unique(topNCompiled(N, Sys.Date()-2))
##         db <- .pkgenv[["db"]]
##         TP <- data.table(Package=topN)
##         P <- db[TP, on="Package"]
##         P <- P[!duplicated(Package),]
##         P[Package %in% c("nlme", "foreign"), Version := gsub("-", ".", Version)]
##         P[, pkgver := paste0("r-cran-", tolower(Package), "_", Version)]

##         P <- P[, isin := is.finite(match(pkgver, B[r2u==TRUE, pkgver])), by=pkgver][isin==FALSE,]
##         P <- P[order(adjdep,ndep,Package), c(1:2, 70:73)]

##         if (verbose) print(P)

##         P <- head(P, min(20, nrow(P)))

##         if (verbose) {
##             print(P)
##             toTargets(P[,Package])
##         }

##         toTargets(P[, Package], file=filename)
##     } else {
##         cat("# needs RcppAPT\n", file=filename)
##     }
## }

## Helper function for GitHub Actions builds and specific to arm64
## N is now obsolete
#  no longer in rd @rdname buildPackage
.getBuildTargets <- function(filename="", N=200, nbatch=40, platform=.platform(), verbose=TRUE) {
    .addBlacklist(.pkgenv[["distribution"]])            # add distro-release blacklist
    .addBlacklist(platform)             		# add arch blacklist (for arm64)

    ## get packages already Built
    #cmd <- "links -dump"
    #url <- "https://r2u.stat.illinois.edu/ubuntu/pool/dists/noble/main/"
    #awk <- r"(awk '/r-.*_ar/ { print $1 "," $2 " "$3 "," $4 }')"  # not arm64.deb as cols get chopped
    #cmd <- paste(cmd, url, "|", awk)
    B <- .allBuilds("noble", platform)
    restr <- paste0(platform, ".deb$")
    B <- B[grepl(restr, file), ]

    ## already in B[, version := gsub("^.*_(.*)_(amd64|all|arch64)\\.deb$", "\\1", file), by=file]
    B[, r2u := grepl("ca2404", version), by=file]  # needed ?
    B[, ver := gsub("(.*)-(\\d\\.ca\\d{4}\\.\\d)$", "\\1", version)] # upstream
    B[, pkgver := gsub("(.*)-(\\d\\.ca\\d{4}\\.\\d)_(.*)$", "\\1", file)]
    if (verbose) print(B)

    db <- .pkgenv[["db"]]
    ## take one: get target packages, here top N compiled
    ##   topN <- unique(topNCompiled(N, Sys.Date()-2))
    ##   TP <- data.table(Package=topN)
    ## take two: get (all) target packages from AP
    ## NB: this is the only one that reflects BioC as we 'stack' ap with BioC but not db
    ap <- .pkgenv[["ap"]]
    TP <- data.table(Package=ap[ap == "CRAN" & NeedsCompilation=="yes", Package])
    ## for either take one or take two: merge with db 
    TP <- data.table(Package=db[NeedsCompilation=="yes", unique(Package)])
    P <- db[TP, on="Package"]
    ## take three: use db directly
    #P <- db[NeedsCompilation=="yes", ]
    P <- P[!duplicated(Package),]
    P[Package %in% c("nlme", "foreign"), Version := gsub("-", ".", Version)]
    P[, pkgver := paste0("r-cran-", tolower(Package), "_", Version)]

    P <- P[, skip := is.finite(match(Package, .pkgenv[["blacklist"]])), by=Package] 
    P <- P[, win := (OS_type == "windows")]
    P <- P[, isin := is.finite(match(pkgver, B[r2u==TRUE, pkgver])), by=pkgver]
    P <- P[isin==FALSE & skip==FALSE & is.na(win),]

    ap <- .pkgenv[["ap"]]
    newP <- ap[, .(Package, Version)][P,on="Package"]
    newP <- newP[ Version==i.Version, ]
    newP[, i.Version:=NULL ]

    P <- newP[order(adjdep,ndep,Package), c(1:2, 70:75)]
    if (verbose) print(P)
    P <- head(P, min(nbatch, nrow(P)))
    if (verbose) {
        print(P)
        .toTargets(P[,Package])
    }

    .toTargets(P[, Package], filename) 	   # actual effect of writing out
    invisible(P)                           # available for debug print if needed
}
