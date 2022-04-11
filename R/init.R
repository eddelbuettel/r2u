
.pkgenv <- new.env(parent=emptyenv())

debug <- FALSE #TRUE
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

.defaultCRANDBFile <- function() {
    if (getRversion() >= "4.0.0") {
        ## ~/.local/share/R/ + package
        pkgdir <- tools::R_user_dir(packageName())
        if (dir.exists(pkgdir)) {
            fname <- file.path(pkgdir, "crandb.rds")
            if (file.exists(fname)) {
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
            #.pkgenv[["user"]] <- cfg[1, "user"]
            .pkgenv[["maintainer"]] <- cfg[1, "maintainer"]
            .pkgenv[["distribution"]] <- cfg[1, "distribution"]
            .pkgenv[["distribution_name"]] <- cfg[1, "distribution_name"]
            .pkgenv[["debhelper_compat"]] <- cfg[1, "debhelper_compat"]
            .pkgenv[["minimum_r_version"]] <- cfg[1, "minimum_r_version"]
            .pkgenv[["debian_policy_version"]] <- cfg[1, "debian_policy_version"]
            .pkgenv[["cache_age_hours_cran_db"]] <- cfg[1, "cache_age_hours_cran_db"]
            if (is.finite(match("optional_cran_mirror", colnames(cfg)))) {
                .pkgenv[["optional_cran_mirror"]] <- cfg[1, "optional_cran_mirror"]
            }
            .pkgenv[["package_cache"]] <- cfg[1, "package_cache"]
        } else {
            .debug_message("No config file")
            .pkgenv[["config_file"]] <- ""
        }
    } else {
        .debug_message("Already have config\n")
    }
}

.checkSystem <- function() {
    bins <- c("osc", "md5sum", "sha1sum", "sha256sum")
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
        } else {
            db <- tools::CRAN_package_db()
            if (dbfile != "") {
                saveRDS(db, dbfile)
            }
        }
        .pkgenv[["db"]] <- db
    } else {
        .debug_message("Have db\n")
    }
}

.onLoad <- function(libname, pkgname) {
    .loadConfig()
    .checkSystem()
    .loadDB()
}

.onAttach <- function(libname, pkgname) {
    .loadConfig()
    .checkSystem()
    .loadDB()
}
