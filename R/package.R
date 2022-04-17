
## downloader from RSPM
.get_package_file <- function(pkg, ver) {
    cachedir <- .getConfig("package_cache")
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

buildPackage <- function(pkg, db, repo=c("CRAN", "Bioc"), debug=FALSE) {
    if (missing(db)) db <- .pkgenv[["db"]]
    stopifnot("db must be data.frame" = inherits(db, "data.frame"))
    repol <- tolower(match.arg(repo))
    if (pkg %in% c("utils", "methods", "stats", "graphics", "grDevices", "grid", "parallel", "tools", "stats")) return(invisible())
    ind <- match(pkg, db[,Package])
    if (is.na(ind)) stop("Package '", pkg, "' not known to package database.", call. = FALSE)
    ap <- .pkgenv[["ap"]]
    aind <- match(pkg, ap[,Package])
    builds <- .pkgenv[["builds"]]

    ## todo: check license and all that
    D <- db[ind,]
    AP <- ap[aind,]
    if (debug) print(D)
    ver <- D[, Version]
    aver <- AP[, Version]
    cat(blue(sprintf("%-16s %-9s %-9s", pkg, ver, aver))) 		# start console log with pkg
    if (ver != aver) {
        cat(red("... not yet available, skipping\n"))
        return(invisible())
    }
    pkgname <- paste0("r-", repol, "-", tolower(pkg)) 			# aka r-cran-namehere
    cand <- paste0(pkgname, "_", ver)
    if (is.finite(match(cand, builds[, pkgver]))) {
        cat(green("... already built, skipping\n"))
        return(invisible)
    }
    ## so we're building one

    file <- .get_package_file(D[,Package], D[,Version]) 		# rspm file, possibly cached

    build_dir <- .getConfig("build_directory")
    if (!dir.exists(build_dir)) stop("Build directory '", build_dir, "' does not exist")
    setwd(build_dir)

    if (!dir.exists(pkg)) dir.create(pkg) 				# namehere inside build
    setwd(pkg)

    if (!dir.exists("debian")) dir.create("debian") 			# debian/
    setwd("debian")
    writeControl(pkg, db, repo)
    writeChangelog(pkg, db, repo)
    writeRules(pkg, repo)
    writeCopyright(pkg, D[, License])

    if (dir.exists(file.path(pkgname, "usr"))) unlink(file.path(pkgname, "usr"), recursive=TRUE)
    if (dir.exists(file.path(pkgname, "DEBIAN"))) unlink(file.path(pkgname, "DEBIAN"), recursive=TRUE)

    instdir <- file.path(pkgname, "usr", "lib", "R", "site-library") 	# unpackaged binary
    if (!dir.exists(instdir)) dir.create(instdir, recursive=TRUE)

    untar(file, exdir=instdir)

    setwd(build_dir)
    container <- paste0("eddelbuettel/r2u:", .getConfig("distribution_name"))
    deps <- if (pkg %in% names(.getConfig("builddeps"))) .getConfig("builddeps")[pkg] else ""
    cmd <- paste0("docker run --rm -ti ",
                  "-v ", getwd(), "/../deb:/deb ",
                  "-v ", getwd(), ":/mnt ",
                  "-w /mnt/", pkg, " ",
                  container, " debBuild.sh ", pkg, " ", deps)
    #print(cmd)
    rc <- system(cmd, ignore.stdout=TRUE)
    if (rc == 0) cat(green("[built] ")) else cat(red("[error", rc, "] "))
    cat("\n")

    invisible()
}

buildAll <- function(pkg, db, repo=c("CRAN", "Bioc"), debug=FALSE) {
    #stopifnot("expect single package (for now)" = length(pkg) == 1)
    if (missing(db)) db <- .pkgenv[["db"]]
    stopifnot("db must be data.frame" = inherits(db, "data.frame"))
    deps <- tools::package_dependencies(pkg, db=db, recursive=TRUE)
    vec <- unique(sort(unname(do.call(c, deps))))
    ignoredres <- sapply(vec, buildPackage, db, repo, debug)
    invisible()
}
