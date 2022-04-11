
.get_package_file <- function(pkg, ver) {
    cachedir <- .getConfig("package_cache")
    path <- file.path(cachedir, paste0(pkg, "_", ver, ".tar.gz"))
    #print(path)
    #if (file.exists(path)) message("yes") else message("no")
    if (!file.exists(path)) {
        repo <- paste0("https://packagemanager.rstudio.com/all/__linux__/", .getConfig("distribution_name"), "/latest")
        rv <- R.version
        agent <- sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), rv$platform, rv$arch, rv$os))
        options(HTTPUserAgent = agent)
        download.packages(pkg, cachedir, repos=repo)
    }
    path
}

buildPackage <- function(pkg, db, repo=c("CRAN", "Bioc"), debug=FALSE) {
    if (missing(db)) db <- .pkgenv[["db"]]
    stopifnot(`db must be data.frame`=inherits(db, "data.frame"))
    repo <- tolower(match.arg(repo))
    if (!inherits(db, "data.table")) setDT(db)
    ind <- match(pkg, db[,Package])
    if (is.na(ind)) stop("Package '", pkg, "' not known to package database.", call. = FALSE)

    ## todo: check license and all that
    D <- db[ind,]
    if (debug) print(D)

    .get_package_file(D[["Package"]], D[["Version"]])
}
