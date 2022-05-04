
## downloader from RSPM
.get_package_file <- function(pkg, ver) {
    cachedir <- .getConfig("package_cache")
    if (!dir.exists(cachedir)) dir.create(cachedir, recursive=TRUE)
    path <- file.path(cachedir, paste0(pkg, "_", ver, ".tar.gz"))
    if (!file.exists(path)) {
        repo <- paste0("https://packagemanager.rstudio.com/all/__linux__/", .getConfig("distribution_name"), "/latest")
        rv <- R.version
        agent <- sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), rv$platform, rv$arch, rv$os))
        options(HTTPUserAgent = agent)
        download.packages(pkg, cachedir, repos = repo, quiet = TRUE)
        cat(green("[downloaded] "))
    } else {
        cat(green("[cached] "))
    }
    path
}

## downloader from bioc
.get_source_file <- function(pkg, ver, ap) {
    cachedir <- .getConfig("package_cache")
    if (!dir.exists(cachedir)) dir.create(cachedir, recursive=TRUE)
    path <- file.path(cachedir, paste0(pkg, "_", ver, ".tar.gz"))
    if (!file.exists(path)) {
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
##' select \sQuote{N} among all (or all compiled) packages.
##'
##' @title Build a Package
##' @param pkg character Name of the CRAN or BioConductor package to build
##' @param debug logical Optional value to show more debugging output, default is \sQuote{FALSE}
##' @param verbose logical Optional value show more verbose progress output, default is \sQuote{FALSE}
##' @param force logical Optional value to force package build from source, default is \sQuote{FALSE}
##' @param xvfb logical Optional value to build under \code{xvfb-run}, default is \sQuote{FALSE}
##' @param suffix character Optional value to override default of \sQuote{.1} affixed to package version
##' @return Nothing as the function is invoked for the side effect of building binary packages
##' @author Dirk Eddelbuettel
buildPackage <- function(pkg, debug=FALSE, verbose=FALSE, force=FALSE, xvfb=FALSE, suffix=".1") {
    db <- .pkgenv[["db"]]
    stopifnot("db must be data.frame" = inherits(db, "data.frame"))
    if (.isBasePackage(pkg)) return(invisible())
    ind <- match(pkg, db[,Package])
    ap <- .pkgenv[["ap"]]
    aind <- match(pkg, ap[,Package])
    if (is.na(ind) && is.na(aind)) {
        if (verbose) message(paste0("Package '", pkg, "' not known to current CRAN package database."))
        return(invisible())
    }
    builds <- .pkgenv[["builds"]]

    repo <- ap[aind, ap]
    if (is.na(repo) || is.na(match(repo, c("CRAN", "Bioc")))) {
        if (verbose) message("skipping ", pkg, " as unknown")
        return(invisible())
    }
    repol <- tolower(repo)

    ## todo: check license and all that
    D <- db[ind,]
    AP <- ap[aind,]
    if (debug) if (repo == "CRAN") print(D) else print(AP)
    ver <- D[, Version]
    aver <- AP[, Version]
    effrepo <- AP[, ap]
    if (is.na(effrepo)) {
        cat(pkg, "missing, skipping\n")
        return(invisible())
    }
    pkgname <- paste0("r-", tolower(effrepo), "-", tolower(pkg)) 			# aka r-cran-namehere
    cand <- paste0(pkgname, "_", ver)
    if (effrepo == "CRAN" && isFALSE(ver == aver)) {
        if (verbose) cat(blue(sprintf("%-22s %-11s %-11s", pkg, ver, aver))) 		# start console log with pkg
        if (verbose) cat(red("[not yet available - skipping]\n"))
        return(invisible())
    } else if (effrepo == "Bioc") {# && isTRUE(ver == aver)) {
        cand <- paste0(pkgname, "_", aver)
        if (is.finite(match(cand, builds[, pkgver])) && isFALSE(force)) { 		# if already built
            if (verbose) {
                cat(blue(sprintf("%-22s %-11s %-11s", pkg, ver, aver)))
                cat(green("[already built - skipping]\n"))
            }
            return(invisible())         						# exit
        } else {
            #cat(blue(sprintf("%-22s %-11s %-11s", pkg, ver, aver))) 		# start console log with pkg
            #cat(red("[building BioC package]\n"))
            #repo <- "Bioc"
        }
    } else {
        ver <- aver
    }
    pkgname <- paste0("r-", tolower(effrepo), "-", tolower(pkg)) 			# aka r-cran-namehere
    cand <- paste0(pkgname, "_", ver)
    if (is.finite(match(cand, builds[, pkgver])) && isFALSE(force)) {
        if (verbose) cat(blue(sprintf("%-22s %-11s %-11s", pkg, ver, aver))) 		# start console log with pkg
        if (verbose) cat(green("[already built - skipping]\n"))
        return(invisible)
    }

    ## so we're building one
    cat(blue(sprintf("%-22s %-11s %-11s", pkg, ver, aver))) 		# start console log with pkg
    if (is.finite(match(pkg, .pkgenv[["blacklist"]]))) {
        cat(red("[blacklisted, skipping]\n"))
        return(invisible)
    }

    file <- if (repo == "CRAN" && isFALSE(force)) {
                .get_package_file(pkg, ver) 				# rspm file, possibly cached
            } else {
                .get_source_file(AP[, Package], AP[, Version], AP)
            }

    build_dir <- .getConfig("build_directory")
    if (!dir.exists(build_dir)) stop("Build directory '", build_dir, "' does not exist")
    setwd(build_dir)

    if (!dir.exists(pkg)) dir.create(pkg) 				# namehere inside build
    setwd(pkg)

    instdir <- file.path("debian", pkgname, "usr", "lib", "R", "site-library") 	# unpackaged binary
    if (!dir.exists(instdir)) dir.create(instdir, recursive=TRUE)

    if (repo == "CRAN" && isFALSE(force)) {
        untar(file, exdir=instdir)
        if (!file.exists(file.path(instdir, pkg, "Meta", "package.rds"))) {
            cat(red("[not prebuilt, forcing source build]\n"))
            buildPackage(pkg, debug, version, force=TRUE, xvfb, suffix)
            return(invisible())
        }
    } else {
        if (!dir.exists("src")) dir.create("src")
        untar(file, exdir="src")
    }

    setwd("debian")

    if (repo == "CRAN" && is.na(match(pkg, db[,Package]))) {
        cat(red("[skipping as not in current CRAN db]\n"))
        return(invisible())
    }

    .writeControl(pkg, db, ap, repo)
    .writeChangelog(pkg, db, ap, repo, suffix=suffix)
    .writeRules(pkg, repo)
    .writeCopyright(pkg, D[, License])
    .writeSourceFormat(pkg)
    r2u_dir <- .getConfig("r2u_directory")
    setwd(r2u_dir)
    container <- paste0("eddelbuettel/r2u_build:", .getConfig("distribution_name"))
    deps <- if (pkg %in% names(.getConfig("builddeps"))) .getConfig("builddeps")[pkg] else ""
    added_deps <- if (repo == "Bioc" || isTRUE(force)) paste(.filterAndMapBuildDepends(pkg, ap), collapse=" ") else ""
    depstr <- if (nchar(deps) + nchar(added_deps) > 0) paste0("-a '", deps, " ", added_deps, "' ") else " "
    cmd <- paste0("docker run --rm -ti ",
                  "-v ", getwd(), ":/mnt ",
                  "-w /mnt/build/", pkg, " ",
                  container, " debBuild.sh ",
                  if (isTRUE(xvfb) || grepl("(tcltk|tkrplot)", depstr)) "-x " else " ",
                  if (repo == "Bioc") "-b " else " ",
                  if (repo == "Bioc" || isTRUE(force)) "-s " else " ",
                  depstr,
                  pkg)
    if (debug) print(cmd)
    rc <- system(cmd, ignore.stdout=!debug)
    if (rc == 0) cat(green("[built] ")) else cat(red("[error", rc, "] "))
    cat("\n")

    invisible()
}

#' @rdname buildPackage
buildAll <- function(pkg, debug=FALSE) {
    db <- .pkgenv[["db"]]
    stopifnot("db must be data.frame" = inherits(db, "data.frame"))
    deps <- tools::package_dependencies(pkg, db=db, recursive=TRUE)
    vec <- unique(sort(c(pkg, unname(do.call(c, deps)))))
    ignoredres <- sapply(vec, buildPackage, debug)
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
    D <- data.table::fread(.getCachedDLLogsFile(date))
    D <- D[, .N, keyby=package][order(N,decreasing=TRUE)]
    D[seq(from, min(from+npkg-1L, nrow(D))),package]
}

#' @rdname buildPackage
topNCompiled <- function(npkg, date=Sys.Date() - 1, from=1L) {
    db <- .pkgenv[["db"]]
    D <- data.table::fread(.getCachedDLLogsFile(date))
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

