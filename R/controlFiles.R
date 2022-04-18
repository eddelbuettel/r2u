
.addDepends <- function(dt, con) {
    if (is.na(dt[,Depends])) return(invisible(NULL))
    dep <- gsub("\\n", "", dt[,Depends])
    dep <- gsub("R \\(.*?\\), ", "", dep, perl=TRUE)
    if (nchar(dep) == 0) return(invisible(NULL))
    deps <- strsplit(dep, ",")[[1]]
    for (i in deps) {
        i <- gsub("^ ", "", i)
        if (i %in% c("utils", "methods", "stats", "graphics", "tools", "stats")) next
        cat(", r-cran-", tolower(i), sep="", file=con, append=TRUE)
    }
}

.addImports <- function(dt, con) {
    if (is.na(dt[,Imports])) return(invisible(NULL))
    imp <- gsub("\\n", "", dt[,Imports])
    imps <- strsplit(imp, ",")[[1]]
    for (i in imps) {
        i <- gsub("^ ", "", i)
        if (i %in% c("utils", "methods", "stats", "graphics", "grDevices", "tools", "stats")) next
        cat(", r-cran-", tolower(i), sep="", file=con, append=TRUE)
    }
}

.addLinkingTo <- function(dt, con) {
    if (is.na(dt[,LinkingTo])) return(invisible(NULL))
    lto <- gsub("\\n", "", dt[,LinkingTo])
    ltos <- strsplit(lto, ",")[[1]]
    for (i in ltos) {
        i <- gsub("^ ", "", i)
        i <- gsub("\\n", "", i)
        if ("Rcpp" == i && grepl("Rcpp", dt[,Imports])) next 	# already covered
        cat(", r-cran-", tolower(i), sep="", file=con, append=TRUE)
    }
}

.addSuggests <- function(dt, con) {
    if (is.na(dt[,Suggests])) return(invisible(NULL))
    sgg <- gsub("\\n", "", dt[,Suggests])
    sggs <- strsplit(sgg, ",")[[1]]
    first <- TRUE
    for (i in sggs) {
        i <- gsub("^ ", "", i)
        i <- gsub("\\n", "", i)
        i <- gsub("== ", "= ", i)
        if (!first) cat(", ", file=con, append=TRUE)
        cat("r-cran-", tolower(i), sep="", file=con, append=TRUE)
        first <- FALSE
    }
}

.hasConfigField <- function(key) {
    is.finite(match(key, names(.pkgenv)))
}

.getConfig <- function(key) {
    stopifnot(`key is not present`=is.finite(match(key, names(.pkgenv))))
    .pkgenv[[key]]
}

writeControl <- function(pkg, db, repo=c("CRAN", "Bioc"), debug=FALSE) {
    if (missing(db)) db <- .pkgenv[["db"]]
    stopifnot(`db must be data.frame`=inherits(db, "data.frame"))
    repo <- tolower(match.arg(repo))
    if (!inherits(db, "data.table")) setDT(db)
    ind <- match(pkg, db[,Package])
    if (is.na(ind)) stop("Package '", pkg, "' not known to package database.", call. = FALSE)

    ## todo: check license and all that
    D <- db[ind,]
    if (debug) print(D)

    lp <- tolower(pkg)
    maint <- .getConfig("maintainer")
    dhcompat <- .getConfig("debhelper_compat")
    rdevver <- .getConfig("minimum_r_version")
    stdver <- .getConfig("debian_policy_version")

    binary <- D[,NeedsCompilation] == "yes"

    con <- file("control", "wt")
    cat("Source: r-", repo, "-", lp, "\n",
        "Section: gnu-r\n",
        "Priority: optional\n",
        "Maintainer: ", maint, "\n",
        "Build-Depends: debhelper-compat (= ", dhcompat, "), r-base-dev (>= ", rdevver, "), dh-r",
        sep="", file=con)
    .addDepends(D, con)
    .addImports(D, con)
    .addLinkingTo(D, con)
    cat("\nStandards-Version: ", stdver, "\n",
        "Homepage: https://cran.r-project.org/package=", pkg, "\n\n",
        "Package: r-", repo, "-", lp, "\n",
        "Architecture: ", if (binary) "any" else "all", "\n",
        "Depends: ", if (binary) "${shlibs:Depends}, " else "", "${misc:Depends}, ${R:Depends}",
        sep="", file=con)
    .addDepends(D, con)
    .addImports(D, con)
    .addLinkingTo(D, con)
    cat("\nSuggests: ", file=con)
    .addSuggests(D, con)
    cat("\nDescription: CRAN Package '", pkg, "' (", gsub("\\n", "", D[,Title]), ")\n", sep="", file=con)
    sapply(Filter(function(x) x != "", strwrap(trimws(D[, Description]), 78, indent=1, exdent=1)), cat, "\n", sep="", file=con)
    cat("\n", file=con)
    close(con)
}

writeChangelog <- function(pkg, db, repo=c("CRAN", "Bioc"), debug=FALSE) {
    if (missing(db)) db <- .pkgenv[["db"]]
    stopifnot(`db must be data.frame`=inherits(db, "data.frame"))
    repo <- tolower(match.arg(repo))
    if (!inherits(db, "data.table")) setDT(db)
    ind <- match(pkg, db[,Package])
    if (is.na(ind)) stop("Package '", pkg, "' not known to package database.", call. = FALSE)

    ## todo: check license and all that
    D <- db[ind,]
    if (debug) print(D)

    lp <- tolower(pkg)
    maint <- .getConfig("maintainer")
    dhcompat <- .getConfig("debhelper_compat")
    distribution <- .getConfig("distribution")
    distribution_name <- .getConfig("distribution_name")

    rel <- paste0("r-", repo, "-", lp)
    ver <- paste0(D[,Version], "-1.ca", gsub("\\.", "", distribution), ".1")
    date <- system("date -R", intern=TRUE)
    con <- file("changelog", "wt")
    cat(rel, " (", ver, ") ", distribution_name, "; urgency=medium\n\n",
        "  * CRANapt build\n\n",
        " -- ", maint, "  ", date, "\n", sep="", file=con)
    close(con)
}

#writeRules <- function(pkg, db) {
writeRules <- function(pkg, repo=c("CRAN", "Bioc")) {
    repo <- tolower(match.arg(repo))
    con <- file("rules", "wt")
    cat("#!/usr/bin/make -f\n",
        "\n",
        "override_dh_prep:\n",
	"\t@echo \"Skipping dh_prep\"\n",
        "\n",
        "override_dh_clean:\n",
	"\t@echo \"Skipping dh_clean\"\n",
        "\n",
        "override_dh_auto_install:\n",
	"\t@echo \"R:Depends=r-base-core (>= ", .getConfig("minimum_r_version"), "), r-api-", .getConfig("r_api_version"), "\" >> debian/r-", repo, "-", tolower(pkg), ".substvars\n",
        "\n",
        "override_dh_auto_build:\n",
	"\t@echo \"Skipping dh_auto_build\"\n",
        "\n",
        sep="", file=con)
    if (pkg == "h2o")
        cat("override_dh_auto_build:\n",
	    "\t@echo \"Skipping dh_auto_build\"\n",
            "\n",
            sep="", file=con)
    cat("%:\n",
        "\tdh $@ --buildsystem R\n",
        sep="", file=con)
    close(con)
}

writeCopyright <- function(pkg, license) {
    con <- file("copyright", "wt")
    cat("This is a binary build of CRAN package '", pkg, "'.\n\n",
        "Its original license is '", license, "'.\n\n",
        "See the included file 'DESCRIPTION' for more details.\n",
        sep="", file=con)
    close(con)
}

writeFiles <- function(pkg, repo=c("CRAN", "Bioc")) {
    stopifnot(`missing db`=is.finite(match("db", names(.pkgenv))))
    repo <- match.arg(repo)

    db <- setDT(.pkgenv[["db"]])
    .downloadTarGz(pkg, db, repo)
    writeControl(pkg, db=db, repo=repo)
    writeChangelog(pkg, db=db, repo=repo)
    writeRules() #pkg, db=db)
    writeDsc(pkg, db=db, repo=repo)
}

.getField <- function(pkg, field, db, repo=c("CRAN", "Bioc")) {
    if (missing(db)) db <- .pkgenv[["db"]]
    stopifnot(`db must be data.frame`=inherits(db, "data.frame"))
    if (!inherits(db, "data.table")) setDT(db)
    ind <- match(pkg, db[,Package])
    if (any(is.na(ind))) stop("Package '", pkg, "' not known to package database.", call. = FALSE)
    if (is.na(match(field, names(db)))) stop("Field '", field, "' not known to package database.", call. = FALSE)
    db[ind, ..field][[1]]
}

getVersion <- function(pkg, db, repo=c("CRAN", "Bioc")) {
    .getField(pkg, "Version", db, repo)
}

.downloadTarGz <- function(pkg, db, repo=c("CRAN", "Bioc"), debug=FALSE) {
    if (missing(db)) db <- .pkgenv[["db"]]
    stopifnot(`db must be data.frame`=inherits(db, "data.frame"))
    repo <- tolower(match.arg(repo))
    if (!inherits(db, "data.table")) setDT(db)
    ind <- match(pkg, db[,Package])
    if (is.na(ind)) stop("Package '", pkg, "' not known to package database.", call. = FALSE)

    ver <- getVersion(pkg, db, repo)
    dst <- paste0(pkg, "_", ver, ".tar.gz")
    if (file.exists(dst))
        return(invisible)
    if (repo == "cran") {
        if (.hasConfigField("optional_cran_mirror")) {
            src <- file.path(.getConfig("optional_cran_mirror"), dst)
            stopifnot(`source file expected but not found`=file.exists(src))
            file.copy(src, dst, overwrite=TRUE, copy.date=TRUE)
        } else {
            download.packages(pkg, ".")
        }
    }
}

## full cycle:
##   osc mkpac pkgname
##   cd pkgname
##   c2d::writeFiles(pkgname, repo="CRAN")
##   osc add debian.* *.tar.gz *.dsc
##   osc build --local-package
##   osc commit -m'r-cran-pkgname version'
