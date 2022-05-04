
.pkgenv <- new.env(parent=emptyenv())

.debug <- FALSE #TRUE
.debug_message <- function(...) if (.debug) message(..., appendLF=FALSE)

.defaultConfigFile <- function() {
    if (getRversion() >= "4.0.0") {
        pkgdir <- tools::R_user_dir(packageName())      # ~/.local/share/R/ + package
        if (dir.exists(pkgdir)) {
            fname <- file.path(pkgdir, "config.dcf")
            if (file.exists(fname)) {
                return(fname)
            }
        }
    }
    return("")
}

.defaultCRANDBFile <- function(force=FALSE) {
    if (getRversion() >= "4.0.0") {
        pkgdir <- tools::R_user_dir(packageName())      # ~/.local/share/R/ + package
        if (dir.exists(pkgdir)) {
            fname <- file.path(pkgdir, "crandb.rds")
            if (file.exists(fname) || force) {
                return(fname)
            }
        } else {
            .debug_message("No package config dir")
        }
    }
    return("")
}

.defaultAPFile <- function(force=FALSE) {
    if (getRversion() >= "4.0.0") {
        pkgdir <- tools::R_user_dir(packageName()) 	# ~/.local/share/R/ + package
        if (dir.exists(pkgdir)) {
            fname <- file.path(pkgdir, "availablepackages.rds")
            if (file.exists(fname) || force) {
                return(fname)
            }
        } else {
            .debug_message("No package config dir")
        }
    }
    return("")
}

.defaultBioCFile <- function(force=FALSE) {
    if (getRversion() >= "4.0.0") {
        pkgdir <- tools::R_user_dir(packageName()) 	# ~/.local/share/R/ + package
        if (dir.exists(pkgdir)) {
            fname <- file.path(pkgdir, "bioc_available_packages.rds")
            if (file.exists(fname) || force) {
                return(fname)
            }
        } else {
            .debug_message("No package config dir")
        }
    }
    return("")
}

.defaultBuildDependsFile <- function() {
    if (getRversion() >= "4.0.0") {
        pkgdir <- tools::R_user_dir(packageName())	# ~/.local/share/R/ + package
        if (dir.exists(pkgdir)) {
            fname <- file.path(pkgdir, "depends.dcf")
            if (file.exists(fname)) {
                return(fname)
            }
        }
    }
    return("")
}

.defaultBlacklistFile <- function(force=FALSE) {
    if (getRversion() >= "4.0.0") {
        pkgdir <- tools::R_user_dir(packageName())      # ~/.local/share/R/ + package
        if (dir.exists(pkgdir)) {
            fname <- file.path(pkgdir, "blacklist.txt")
            if (file.exists(fname) || force) {
                return(fname)
            }
        } else {
            .debug_message("No package config dir")
        }
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
            .pkgenv[["cache_age_hours_cran_db"]] <- cfg[1, "cache_age_hours_cran_db"]
            .pkgenv[["package_cache"]] <- cfg[1, "package_cache"]
            .pkgenv[["r2u_directory"]] <- cfg[1, "r2u_directory"]
            .pkgenv[["build_directory"]] <- cfg[1, "build_directory"]
            .pkgenv[["deb_directory"]] <- cfg[1, "deb_directory"]
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
    } else {
        stop("Unknown build target: ", tgt, call. = FALSE)
    }
}

.checkSystem <- function() {
    bins <- c("docker", "apt", "dpkg", "md5sum", "sha1sum", "sha256sum")
    res <- Sys.which(bins)
    if (any(res==""))
        stop("Missing binaries for '", paste(names(res[res==""]), collapse=", "), "'.", call. = FALSE)
    invisible()
}

.loadDB <- function() {
    if (is.na(match("db", names(.pkgenv)))) {
        .debug_message("Reading db\n")
        dbfile <- .defaultCRANDBFile()
        hrs <- .pkgenv[["cache_age_hours_cran_db"]]
        if (file.exists(dbfile) &&
            as.numeric(difftime(Sys.time(), file.info(dbfile)$ctime, units="hours")) < hrs) {
            db <- readRDS(dbfile)
            .debug_message("Cached db\n")
        } else {
            .debug_message("Fresh db\n")
            db <- tools::CRAN_package_db()
            dbfile <- .defaultCRANDBFile(TRUE)
            saveRDS(db, dbfile)
            .debug_message("Written db\n")
        }
        .pkgenv[["db"]] <- data.table(as.data.frame(db))
    } else {
        .debug_message("Have db\n")
    }
}

.loadAP <- function() {
    if (is.na(match("ap", names(.pkgenv)))) {
        .debug_message("Getting ap\n")
        apfile <- .defaultAPFile()
        hrs <- .pkgenv[["cache_age_hours_cran_db"]]
        if (file.exists(apfile) &&
            as.numeric(difftime(Sys.time(), file.info(apfile)$ctime, units="hours")) < hrs) {
            ap <- readRDS(apfile)
            .debug_message("Cached ap\n")
        } else {
            .debug_message("Fresh ap\n")

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

            #rspmfocalrepo <- paste0("https://packagemanager.rstudio.com/all/__linux__/focal/latest")
            #apRSPMfocal <- data.table(ap="CRAN", as.data.frame(available.packages(repos=rspmfocalrepo)))
            #ap <- merge(apRSPMfocal, apBIOC, all=TRUE)
            rspmjammyrepo <- paste0("https://packagemanager.rstudio.com/all/__linux__/jammy/latest")
            apRSPMjammy <- data.table(ap="CRAN", as.data.frame(available.packages(repos=rspmjammyrepo)))
            ap <- merge(apRSPMjammy, apBIOC, all=TRUE)

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

.loadBuilds <- function() {
    dd <- .pkgenv[["deb_directory"]]
    cwd <- getwd()
    setwd(dd)
    fls <- list.files(".", pattern="\\.deb$", full.names=FALSE)
    n1 <- tools::file_path_sans_ext(fls)
    n2 <- gsub("-\\d+.ca(20|22)04.\\d+_(all|amd64)$", "", n1)
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

.loadBlacklist <- function() {
    blacklistfile <- .defaultBlacklistFile()
    if (blacklistfile == "") {
        .pkgenv[["blacklist"]] <- character()
    } else {
        skipped <- readLines(blacklistfile)
        .pkgenv[["blacklist"]] <- skipped
    }
}

.onLoad <- function(libname, pkgname) {
    .loadConfig()
    .checkSystem()
    .loadDB()
    .loadAP()
    .loadBuilds()
    .loadBuildDepends()
    .loadBlacklist()
}

.onAttach <- function(libname, pkgname) {
    .loadConfig()
    .checkSystem()
    .loadDB()
    .loadAP()
    .loadBuilds()
    .loadBuildDepends()
    .loadBlacklist()
}
