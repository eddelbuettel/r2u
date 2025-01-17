
.pkgenv <- new.env(parent=emptyenv())

.debug <- FALSE #TRUE#
.debug_message <- function(...) if (.debug) message(..., appendLF=FALSE)

.defaultConfigFile <- function() {
    pkgdir <- tools::R_user_dir(packageName())      # ~/.local/share/R/ + package
    if (dir.exists(pkgdir)) {
        fname <- file.path(pkgdir, "config.dcf")
        if (file.exists(fname)) {
            return(fname)
        }
    }
    return("")
}

.defaultCRANDBFile <- function(force=FALSE) {
    pkgdir <- tools::R_user_dir(packageName())      # ~/.local/share/R/ + package
    if (dir.exists(pkgdir)) {
        fname <- file.path(pkgdir, "crandb.rds")
        if (file.exists(fname) || force) {
            return(fname)
        }
    } else {
        .debug_message("No package config dir")
    }
    return("")
}

.defaultAPFile <- function(force=FALSE) {
    pkgdir <- tools::R_user_dir(packageName()) 	# ~/.local/share/R/ + package
    if (dir.exists(pkgdir)) {
        fname <- file.path(pkgdir, "availablepackages.rds")
        if (file.exists(fname) || force) {
            return(fname)
        }
    } else {
        .debug_message("No package config dir")
    }
    return("")
}

.defaultBioCFile <- function(force=FALSE) {
    pkgdir <- tools::R_user_dir(packageName()) 	# ~/.local/share/R/ + package
    if (dir.exists(pkgdir)) {
        fname <- file.path(pkgdir, "bioc_available_packages.rds")
        if (file.exists(fname) || force) {
            return(fname)
        }
    } else {
        .debug_message("No package config dir")
    }
    return("")
}

.defaultBuildDependsFile <- function(dist = "") {
    pkgdir <- tools::R_user_dir(packageName())	# ~/.local/share/R/ + package
    if (dir.exists(pkgdir)) {
        if (dist == "") {
            fname <- file.path(pkgdir, "depends.dcf")
        } else {
            fname <- file.path(pkgdir, paste0("depends.", dist, ".dcf"))
        }
        if (file.exists(fname)) {
            return(fname)
        }
    } else {
        .debug_message("No package config dir")
    }
    return("")
}

.defaultBlacklistFile <- function(dist = "", force = FALSE) {
    pkgdir <- tools::R_user_dir(packageName())      # ~/.local/share/R/ + package
    if (dir.exists(pkgdir)) {
        if (dist == "") {
            fname <- file.path(pkgdir, "blacklist.txt")
        } else {
            fname <- file.path(pkgdir, paste0("blacklist.", dist, ".txt"))
        }
        if (file.exists(fname) || force) {
            return(fname)
        }
    } else {
        .debug_message("No package config dir")
    }
    return("")
}

.defaultRunTimeDependsFile <- function(dist = "") {
    pkgdir <- tools::R_user_dir(packageName())	# ~/.local/share/R/ + package
    if (dir.exists(pkgdir)) {
        if (dist == "") {
            fname <- file.path(pkgdir, "runtimedepends.dcf")
        } else {
            fname <- file.path(pkgdir, paste0("runtimedepends.", dist, ".dcf"))
        }
        if (file.exists(fname)) {
            return(fname)
        }
    } else {
        .debug_message("No package config dir")
    }
    return("")
}


.loadConfig <- function() {
    if (is.na(match("config_file", names(.pkgenv)))) {
        .debug_message("Reading config\n")
        cfgfile <- .defaultConfigFile()
        if (cfgfile != "") {
            cfg <- read.dcf(cfgfile)
            .pkgenv[["config_file"]] <- cfgfile
            .pkgenv[["maintainer"]] <- cfg[1, "maintainer"]
            .pkgenv[["debhelper_compat"]] <- cfg[1, "debhelper_compat"]
            .pkgenv[["minimum_r_version"]] <- cfg[1, "minimum_r_version"]
            .pkgenv[["r_api_version"]] <- cfg[1, "r_api_version"]
            .pkgenv[["bioc_version"]] <- cfg[1, "bioc_version"]
            .pkgenv[["debian_policy_version"]] <- cfg[1, "debian_policy_version"]
            .pkgenv[["cache_age_hours_cran_db"]] <- as.integer(cfg[1, "cache_age_hours_cran_db"])
            .pkgenv[["package_cache"]] <- cfg[1, "package_cache"]
            .pkgenv[["r2u_directory"]] <- cfg[1, "r2u_directory"]
            .pkgenv[["build_directory"]] <- cfg[1, "build_directory"]
            .pkgenv[["deb_directory"]] <- cfg[1, "deb_directory"]
            .pkgenv[["build_container"]] <- cfg[1, "build_container"]

            ## fallbacks, overriden when 'tgt' specified
            .pkgenv[["distribution"]] <- "20.04"
            .pkgenv[["distribution_name"]] <- "focal"

        } else {
            .debug_message("No config file")
            .pkgenv[["config_file"]] <- ""
        }
    } else {
        .debug_message("Already have config\n")
    }
}

.checkTarget <- function(tgt) {
    if (tgt == "20.04" || tgt == "focal") {
        .pkgenv[["distribution"]] <- "20.04"
        .pkgenv[["distribution_name"]] <- "focal"
    } else if (tgt == "22.04" || tgt == "jammy") {
        .pkgenv[["distribution"]] <- "22.04"
        .pkgenv[["distribution_name"]] <- "jammy"
    } else if (tgt == "24.04" || tgt == "noble") {
        .pkgenv[["distribution"]] <- "24.04"
        .pkgenv[["distribution_name"]] <- "noble"
    } else {
        stop("Unknown build target: ", tgt, call. = FALSE)
    }
}

.checkSystem <- function() {
    bins <- c("docker", "apt", "dpkg", "date", "md5sum", "sha1sum", "sha256sum")
    res <- Sys.which(bins)
    if (any(res==""))
        stop("Missing binaries for '", paste(names(res[res==""]), collapse=", "), "'.", call. = FALSE)
    invisible()
}

.loadDB <- function(hrs = .pkgenv[["cache_age_hours_cran_db"]]) {
    if (is.na(match("db", names(.pkgenv)))) {
        .debug_message("Reading db\n")
        dbfile <- .defaultCRANDBFile()
        if (file.exists(dbfile) && as.numeric(difftime(Sys.time(), file.info(dbfile)$ctime, units="hours")) < hrs) {
            db <- readRDS(dbfile)
            .debug_message("Cached db\n")
        } else {
            .debug_message("Fresh db\n")
            db <- data.table(as.data.frame(tools::CRAN_package_db()))

            #message("Expanding CRAN database. One moment...")
            p <- tools::package_dependencies(db[, Package], db=db, recursive=TRUE)
            pp <- lapply(p, length)
            ppp <- sapply(pp, `[`)
            np <- data.table(Package=names(ppp), ndep=ppp)
            db <- db[np, on="Package"]

            ## adjust out the base packages
            baserevs <- tools::package_dependencies(.basePkgs, db=db, reverse=TRUE)
            db[, adjdep := ndep]
            for (br in names(baserevs)) db[Package %in% baserevs[[br]], adjdep := adjdep - 1]

            dbfile <- .defaultCRANDBFile(TRUE)
            saveRDS(db, dbfile)
            .debug_message("Written db\n")
        }
        .pkgenv[["db"]] <- data.table(as.data.frame(db))
    } else {
        .debug_message("Have db\n")
    }
}

.adjustDB <- function() {
    dbfile <- .defaultCRANDBFile()
    db <- readRDS(dbfile)
    db
}

.loadAP <- function(hrs = .pkgenv[["cache_age_hours_cran_db"]]) {
    if (is.na(match("ap", names(.pkgenv)))) {
        .debug_message("Getting ap\n")
        apfile <- .defaultAPFile()
        if (file.exists(apfile) &&
            as.numeric(difftime(Sys.time(), file.info(apfile)$ctime, units="hours")) < hrs) {
            ap <- readRDS(apfile)
            .debug_message("Cached ap\n")
        } else {
            .debug_message("Fresh ap\n")

            ## also:
            ##
            ## db <- available.packages(repos = BiocManager::repositories())
            ## deps <- tools::package_dependencies("Rgraphviz", db, recursive=TRUE)

            ## cf  contrib.url(BiocManager::repositories())
            ##     [1] "https://bioconductor.org/packages/3.14/bioc/src/contrib"
            ##     [2] "https://bioconductor.org/packages/3.14/data/annotation/src/contrib"
            ##     [3] "https://bioconductor.org/packages/3.14/data/experiment/src/contrib"
            biocrepo <- paste0("https://bioconductor.org/packages/", .getConfig("bioc_version"), "/bioc")
            apBIOC <- data.table(ap="Bioc", as.data.frame(available.packages(repos=biocrepo)))
            biocdataannrepo <- paste0("https://bioconductor.org/packages/", .getConfig("bioc_version"), "/data/annotation")
            apBIOCdataann <- data.table(ap="Bioc", as.data.frame(available.packages(repos=biocdataannrepo)))
            apBIOC <- merge(apBIOC, apBIOCdataann, all=TRUE)
            biocdataexprepo <- paste0("https://bioconductor.org/packages/", .getConfig("bioc_version"), "/data/experiment")
            apBIOCdataexp <- data.table(ap="Bioc", as.data.frame(available.packages(repos=biocdataexprepo)))
            apBIOC <- merge(apBIOC, apBIOCdataexp, all=TRUE)

            ## the returned set is tools::CRAN_package_db() and _not_ dependent on the distribution name
            ppmrepo <- paste0("https://packagemanager.posit.co/all/__linux__/jammy/latest")
            apPPM <- data.table(ap="CRAN", as.data.frame(available.packages(repos=ppmrepo)))
            ap <- merge(apPPM, apBIOC, all=TRUE)

            ap[, deb := paste0("r-", tolower(ap), "-", tolower(Package))]

            apfile <- .defaultAPFile(TRUE)
            saveRDS(ap, apfile)
            .debug_message("Written ap\n")
        }
        .pkgenv[["ap"]] <- data.table(as.data.frame(ap))
    } else {
        .debug_message("Have ap\n")
    }
}

.loadBuilds <- function(tgt) {
    if (missing(tgt)) tgt <- .pkgenv[["distribution_name"]]
    dd <- file.path(.pkgenv[["deb_directory"]], "dists", tgt, "main")
    cwd <- getwd()
    setwd(dd)
    fls <- list.files(".", pattern="\\.deb$", full.names=FALSE)
    n1 <- tools::file_path_sans_ext(fls)
    n2 <- gsub("-\\d+.ca(20|22|24)04.\\d+_(all|amd64)$", "", n1)
    n3 <- gsub(".*-\\d+.ca(\\d{4}).\\d+_.*", "\\1", n1)
    B <- data.table(name=fls, pkgver=n2, file.info(fls), tgt=n3)
    .pkgenv[["builds"]] <- B
}

.loadBuildDepends <- function() {
    depfile <- .defaultBuildDependsFile()
    if (depfile == "") {
        .pkgenv[["builddeps"]] <- character()
    } else {
        deps <- read.dcf(depfile)
        .pkgenv[["builddeps"]] <- deps[1,,drop=TRUE]
    }
}

.addBuildDepends <- function(dist) {
    depfile <- .defaultBuildDependsFile(dist)
    if (depfile != "") {
        deps <- read.dcf(depfile)
        .pkgenv[["builddeps"]] <- c(.pkgenv[["builddeps"]], deps[1,,drop=TRUE])
    }
}


.loadBlacklist <- function() {
    blacklistfile <- .defaultBlacklistFile()
    if (blacklistfile == "") {
        .pkgenv[["blacklist"]] <- character()
    } else {
        skipped <- Filter(\(x) !grepl("^#", x),  readLines(blacklistfile))
        .pkgenv[["blacklist"]] <- skipped
    }
}

.addBlacklist <- function(dist) {
    blacklistfile <- .defaultBlacklistFile(dist)
    if (blacklistfile != "") {
        skipped <- Filter(\(x) !grepl("^#", x),  readLines(blacklistfile))
        .pkgenv[["blacklist"]] <- c(.pkgenv[["blacklist"]], skipped)
    }
}

.loadRuntimedepends <- function() {
    runtimedepsfile <- .defaultRunTimeDependsFile()
    if (runtimedepsfile == "") {
        .pkgenv[["runtimedeps"]] <- character()
    } else {
        skipped <- Filter(\(x) !grepl("^#", x),  readLines(runtimedepsfile))
        .pkgenv[["runtimedeps"]] <- skipped
    }
t}

.addRuntimedepends <- function(dist) {
    runtimedepsfile <- .defaultRunTimeDependsFile(dist)
    if (runtimedepsfile != "") {
        skipped <- Filter(\(x) !grepl("^#", x),  readLines(runtimedepsfile))
        .pkgenv[["runtimedeps"]] <- c(.pkgenv[["runtimedeps"]], skipped)
    }
}


.setOptions <- function() {
    options(timeout = 180) 		# up from default of 60
}

.onLoad <- function(libname, pkgname) {
    .loadConfig()
    .checkSystem()
    .loadDB()
    .loadAP()
    .loadBuilds()
    .loadBuildDepends()
    .loadBlacklist()
    .loadRuntimedepends()
    .setOptions()
}

.onAttach <- function(libname, pkgname) {
    .loadConfig()
    .checkSystem()
    .loadDB()
    .loadAP()
    .loadBuilds()
    .loadBuildDepends()
    .loadBlacklist()
    .loadRuntimedepends()
    .setOptions()
}
