
.basePkgs <- c("base", "compiler", "datasets", "graphics", "grDevices", "grid", "methods", "parallel",
               "splines", "stats", "stats4", "tcltk", "tools", "translations", "utils")
## also see tools:::.get_standard_package_names() or explicitly joining list elements 'base'
## and 'recommended' in unname(do.call(c, tools:::.get_standard_package_names()))
## or just 'base' in sort(tools:::.get_standard_package_names()$base) which is almost the above
## (modulo 'translations')

.isBasePackage <- function(pkg) {
    pkg %in% .basePkgs
}

.addDepends <- function(dt, ap, con) {
    if (is.na(dt[,Depends])) return(invisible(NULL))

    dep <- gsub("\\n", "", dt[,Depends])
    dep <- gsub("R \\(.*?\\)[, ]*", "", dep, perl=TRUE)

    curpkg <- dt[1,Package]
    rtdeps <- .pkgenv[["runtimedeps"]]
    has_rtdeps <- any(grepl(paste0("^",curpkg,":"), rtdeps))
    if (nchar(dep) == 0 && !has_rtdeps)
        return(invisible(NULL))

    deps <- strsplit(dep, ",")[[1]]
    for (i in deps) {
        i <- gsub("^ ", "", i)
        if (.isBasePackage(i)) next
        j <- gsub(" ?\\(.*?\\)", "", i)
        p <- ap[Package==j, deb]
        cat(", ", p ,sep="", file=con, append=TRUE)
    }

    if (has_rtdeps) {
        rtdep <- read.dcf(textConnection(rtdeps), curpkg)[[1]]
        cat(", ", rtdep, sep="", file=con, append=TRUE)
    }
}

.addImports <- function(dt, ap, con) {
    if (is.na(dt[,Imports])) return(invisible(NULL))
    imp <- gsub("\\n", "", dt[,Imports])
    imps <- strsplit(imp, ",")[[1]]
    for (i in imps) {
        i <- gsub("^ ", "", i)
        if (.isBasePackage(i)) next
        j <- gsub(" ?\\(.*?\\)", "", i)
        p <- ap[Package==j, deb]
        cat(", ", p ,sep="", file=con, append=TRUE)
    }
}

.addLinkingTo <- function(dt, ap, con) {
    if (is.na(dt[,LinkingTo])) return(invisible(NULL))
    lto <- gsub("\\n", "", dt[,LinkingTo])
    ltos <- strsplit(lto, ",")[[1]]
    for (i in ltos) {
        i <- gsub("^ ", "", i)
        i <- gsub("\\n", "", i)
        if ("Rcpp" == i && grepl("Rcpp", dt[,Imports])) next 	# already covered
        j <- gsub(" ?\\(.*?\\)", "", i)
        p <- ap[Package==j, deb]
        cat(", ", p ,sep="", file=con, append=TRUE)
    }
}

.addSuggests <- function(dt, ap, con) {
    if (is.na(dt[,Suggests])) return(invisible(NULL))
    sgg <- gsub("\\n", "", dt[,Suggests])
    sggs <- strsplit(sgg, ",")[[1]]
    first <- TRUE
    for (i in sggs) {
        i <- gsub("^ ", "", i)
        i <- gsub("\\n", "", i)
        i <- gsub("== ", "= ", i)
        if (!first) cat(", ", file=con, append=TRUE)
        j <- gsub(" ?\\(.*?\\)", "", i)
        p <- ap[Package==j, deb]
        cat(p ,sep="", file=con, append=TRUE)
        first <- FALSE
    }
}

.hasConfigField <- function(key) {
    is.finite(match(key, names(.pkgenv)))
}

.getConfig <- function(key) {
    stopifnot("key is not present" = is.finite(match(key, names(.pkgenv))))
    .pkgenv[[key]]
}

.writeControl <- function(pkg, db, ap, repo=c("CRAN", "Bioc"), debug=FALSE) {
    if (missing(db)) db <- .pkgenv[["db"]]
    stopifnot("db must be data.frame" = inherits(db, "data.frame"))
    repol <- tolower(match.arg(repo))
    if (!inherits(db, "data.table")) setDT(db)
    ind <- match(pkg, db[,Package])
    aind <- match(pkg, ap[,Package])

    if (repo == "CRAN" && is.na(ind)) stop("Package '", pkg, "' not known to package database.", call. = FALSE)

    ## todo: check license and all that
    D <- if (repo == "CRAN") db[ind,] else ap[aind,]
    if (debug) print(D)
    lp <- tolower(pkg)

    if (! "Title" %in% names(D)) {
        cf <- read.dcf(file.path("..", "src", pkg, "DESCRIPTION"))
        newD <- data.table(Package = cf[1, "Package"], Title = cf[1, "Title"], Description = cf[1, "Description"])
        D <- D[newD, on="Package"]
    }

    maint <- .getConfig("maintainer")
    dhcompat <- .getConfig("debhelper_compat")
    rdevver <- .getConfig("minimum_r_version")
    stdver <- .getConfig("debian_policy_version")

    binary <- D[,NeedsCompilation] == "yes"

    con <- file("control", "wt")
    cat("Source: r-", repol, "-", lp, "\n",
        "Section: gnu-r\n",
        "Priority: optional\n",
        "Maintainer: ", maint, "\n",
        "Build-Depends: debhelper-compat (= ", dhcompat, "), r-base-dev (>= ", rdevver, "), dh-r",
        sep="", file=con)
    .addDepends(D, ap, con)
    .addImports(D, ap, con)
    .addLinkingTo(D, ap, con)
    cat("\nStandards-Version: ", stdver, "\n",
        "Homepage: https://cran.r-project.org/package=", pkg, "\n\n",
        "Package: r-", repol, "-", lp, "\n",
        "Architecture: ", if (binary) "any" else "all", "\n",
        "Depends: ", if (binary) "${shlibs:Depends}, " else "", "${misc:Depends}, ${R:Depends}",
        sep="", file=con)
    .addDepends(D, ap, con)
    .addImports(D, ap, con)
    .addLinkingTo(D, ap, con)
    cat("\nSuggests: ", file=con)
    .addSuggests(D, ap, con)
    cat("\nDescription: ", repo, " Package '", pkg, "' (", gsub("\\n", "", D[,Title]), ")\n", sep="", file=con)
    sapply(Filter(function(x) x != "", strwrap(trimws(D[, Description]), 78, indent=1, exdent=1)), cat, "\n", sep="", file=con)
    cat("\n", file=con)
    close(con)
}

.writeChangelog <- function(pkg, db, ap, repo=c("CRAN", "Bioc"), debug=FALSE, suffix=".1", debver="1.", plusdfsg=FALSE) {
    if (missing(db)) db <- .pkgenv[["db"]]
    stopifnot("db must be data.frame" = inherits(db, "data.frame"))
    repo <- tolower(match.arg(repo))
    if (!inherits(db, "data.table")) setDT(db)
    ind <- match(pkg, db[,Package])
    aind <- match(pkg, ap[,Package])

    if (repo == "CRAN" && is.na(ind)) stop("Package '", pkg, "' not known to package database.", call. = FALSE)

    ## todo: check license and all that
    #D <- db[ind,]
    D <- ap[aind,]
    if (debug) print(D)

    lp <- tolower(pkg)
    maint <- .getConfig("maintainer")
    dhcompat <- .getConfig("debhelper_compat")
    distribution <- .getConfig("distribution")
    distribution_name <- .getConfig("distribution_name")
    upstreamversion <- D[,Version]
    if (pkg %in% c("foreign", "nlme")) {
        upstreamversion <- gsub("-", ".", upstreamversion)
    }
    if (pkg %in% c("sp")) {
        upstreamversion <- paste0("1:", upstreamversion)
    }

    rel <- paste0("r-", repo, "-", lp)
    ver <- paste0(upstreamversion,
                  if (plusdfsg) "+dfsg" else "",
                  "-",
                  debver,        			# usually "1.",
                  "ca",					# for cranapt
                  gsub("\\.", "", distribution),	# eg take out "." from "22.04"
                  suffix)                               # usually ".1"

    date <- system("date -R", intern=TRUE)
    con <- file("changelog", "wt")
    cat(rel, " (", ver, ") ", distribution_name, "; urgency=medium\n\n",
        "  * CRANapt build\n\n",
        " -- ", maint, "  ", date, "\n", sep="", file=con)
    close(con)
}

.writeRules <- function(pkg, repo=c("CRAN", "Bioc")) {
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
    if (pkg %in% c("h2o", "XLConnect")) {
        cat("override_dh_auto_build:\n",
	    "\t@echo \"Skipping dh_auto_build\"\n",
            "\n",
            sep="", file=con)
        cat("override_dh_strip_nondeterminism:\n",
	    "\t@echo \"Skipping dh_strip_nondeterminism\"\n",
            "\n",
            sep="", file=con)
    }
    cat("%:\n",
        "\tdh $@ --buildsystem R\n",
        sep="", file=con)
    close(con)
}

.writeCopyright <- function(pkg, license) {
    con <- file("copyright", "wt")
    cat("This is a binary build of CRAN package '", pkg, "'.\n\n",
        "Its original license is '", license, "'.\n\n",
        "See the included file 'DESCRIPTION' for more details.\n",
        sep="", file=con)
    close(con)
}

.writeSourceFormat <- function(pkg) {
    srcfmtdir <- "source"
    if (!dir.exists(srcfmtdir)) dir.create(srcfmtdir)
    con <- file("source/format", "wt")
    ## cat("3.0 (quilt)", file=con)  # requires source tarball
    cat("1.0", file=con)
    close(con)
}


.getField <- function(pkg, field, db, repo=c("CRAN", "Bioc")) {
    if (missing(db)) db <- .pkgenv[["db"]]
    stopifnot("db must be data.frame" = inherits(db, "data.frame"))
    if (!inherits(db, "data.table")) setDT(db)
    ind <- match(pkg, db[,Package])
    if (any(is.na(ind))) stop("Package '", pkg, "' not known to package database.", call. = FALSE)
    if (is.na(match(field, names(db)))) stop("Field '", field, "' not known to package database.", call. = FALSE)
    db[ind, ..field][[1]]
}

.getVersion <- function(pkg, db, repo=c("CRAN", "Bioc")) {
    .getField(pkg, "Version", db, repo)
}

.downloadTarGz <- function(pkg, db, repo=c("CRAN", "Bioc"), debug=FALSE) {
    if (missing(db)) db <- .pkgenv[["db"]]
    stopifnot(`db must be data.frame`=inherits(db, "data.frame"))
    repo <- tolower(match.arg(repo))
    if (!inherits(db, "data.table")) setDT(db)
    ind <- match(pkg, db[,Package])
    if (is.na(ind)) {
        message("Package '", pkg, "' not known to package database.")
        return(FALSE)
    }
    ver <- .getVersion(pkg, db, repo)
    dst <- paste0(pkg, "_", ver, ".tar.gz")
    if (file.exists(dst))
        return(TRUE)
    if (repo == "cran") {
        download.packages(pkg, ".")
        return(TRUE)
    }
    return(FALSE)
}
