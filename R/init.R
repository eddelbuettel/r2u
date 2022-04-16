
.pkgenv <- new.env(parent=emptyenv())

debug <- FALSE #TRUE #
.debug_message <- function(...) if (debug) message(..., appendLF=FALSE)

.defaultConfigFile <- function() {
    if (getRversion() >= "4.0.0") {
        ## ~/.local/share/R/ + package
        pkgdir <- tools::R_user_dir(packageName())
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
        ## ~/.local/share/R/ + package
        pkgdir <- tools::R_user_dir(packageName())
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
        ## ~/.local/share/R/ + package
        pkgdir <- tools::R_user_dir(packageName())
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

.defaultBuildDependsFile <- function() {
    if (getRversion() >= "4.0.0") {
        ## ~/.local/share/R/ + package
        pkgdir <- tools::R_user_dir(packageName())
        if (dir.exists(pkgdir)) {
            fname <- file.path(pkgdir, "depends.dcf")
            if (file.exists(fname)) {
                return(fname)
            }
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
            #.pkgenv[["user"]] <- cfg[1, "user"]
            .pkgenv[["maintainer"]] <- cfg[1, "maintainer"]
            .pkgenv[["distribution"]] <- cfg[1, "distribution"]
            .pkgenv[["distribution_name"]] <- cfg[1, "distribution_name"]
            .pkgenv[["debhelper_compat"]] <- cfg[1, "debhelper_compat"]
            .pkgenv[["minimum_r_version"]] <- cfg[1, "minimum_r_version"]
            .pkgenv[["r_api_version"]] <- cfg[1, "r_api_version"]
            .pkgenv[["debian_policy_version"]] <- cfg[1, "debian_policy_version"]
            .pkgenv[["cache_age_hours_cran_db"]] <- cfg[1, "cache_age_hours_cran_db"]
            if (is.finite(match("optional_cran_mirror", colnames(cfg)))) {
                .pkgenv[["optional_cran_mirror"]] <- cfg[1, "optional_cran_mirror"]
            }
            .pkgenv[["package_cache"]] <- cfg[1, "package_cache"]
            .pkgenv[["build_directory"]] <- cfg[1, "build_directory"]
        } else {
            .debug_message("No config file")
            .pkgenv[["config_file"]] <- ""
        }
    } else {
        .debug_message("Already have config\n")
    }
}

.checkSystem <- function() {
    bins <- c("docker", "md5sum", "sha1sum", "sha256sum")
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
        .pkgenv[["db"]] <- db
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
            repo <- paste0("https://packagemanager.rstudio.com/all/__linux__/", .getConfig("distribution_name"), "/latest")
            ap <- available.packages(repo=repo)
            apfile <- .defaultAPFile(TRUE)
            saveRDS(ap, apfile)
            .debug_message("Written ap\n")
        }
        .pkgenv[["ap"]] <- ap
    } else {
        .debug_message("Have ap\n")
    }
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

.onLoad <- function(libname, pkgname) {
    .loadConfig()
    .checkSystem()
    .loadDB()
    .loadAP()
    .loadBuildDepends()
}

.onAttach <- function(libname, pkgname) {
    .loadConfig()
    .checkSystem()
    .loadDB()
    .loadAP()
    .loadBuildDepends()
}
