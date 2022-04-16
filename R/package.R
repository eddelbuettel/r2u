
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
    stopifnot(`db must be data.frame`=inherits(db, "data.frame"))
    repol <- tolower(match.arg(repo))
    if (!inherits(db, "data.table")) setDT(db)
    ind <- match(pkg, db[,Package])
    if (is.na(ind)) stop("Package '", pkg, "' not known to package database.", call. = FALSE)

    ## todo: check license and all that
    D <- db[ind,]
    if (debug) print(D)

    cat(blue(sprintf("%-16s ", pkg)))   				# start console log with pkg

    pkgname <- paste0("r-", repol, "-", tolower(pkg)) 			# aka r-cran-namehere
    file <- .get_package_file(D[["Package"]], D[["Version"]]) 		# rspm file, possibly cached

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
    cmd <- paste0("docker run --rm -ti -v ", getwd(), ":/mnt -w /mnt/", pkg, " ",
                  container, " debBuild.sh ", pkg, " ", deps)
    #print(cmd)
    rc <- system(cmd, ignore.stdout=TRUE)
    if (rc == 0) cat(green("[built] ")) else cat(red("[error", rc, "] "))
    cat("\n")

    invisible()
}
