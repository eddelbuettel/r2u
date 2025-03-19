
.pkgenv <- new.env(parent=emptyenv())

.debug <- FALSE #TRUE
.debug_message <- function(...) if (.debug) message(..., appendLF=FALSE)

.in.docker <- function() file.exists("/.dockerenv")

.platform <- function() {
    machine <- Sys.info()[["machine"]]
    switch(machine,
           "x86_64" = "amd64",
           "aarch64" = "arm64",
           NA_character_)
}

.createDefaultConfiguration <- function() { 	    # opt-in helper function not called at load
    pkgdir <- tools::R_user_dir(packageName())      # ~/.local/share/R/ + package
    if (!dir.exists(pkgdir)) {
        dir.create(pkgdir, recursive = TRUE)
    } 
    fname <- file.path(pkgdir, "config.dcf")

    if (requireNamespace("whoami", quietly=TRUE)) {
        cat("maintainer:", whoami::fullname(), paste0("<", whoami::email_address(), ">"), "\n",
            file = fname, append = FALSE)
    } else {
        cat("maintainer: r2u builder <none@email.com>\n", file = fname, append = FALSE)
    }
    cat("in_docker:", .in.docker(), "\n",   file = fname, append = TRUE)
    cat("debhelper_compat: 13\n",           file = fname, append = TRUE)
    cat("minimum_r_version: 4.4.0\n",       file = fname, append = TRUE)
    cat("r_api_version: 4.0\n",             file = fname, append = TRUE)
    cat("bioc_version: 3.20\n",             file = fname, append = TRUE)
    cat("debian_policy_version: 4.7.0\n",   file = fname, append = TRUE)
    cat("cache_age_hours_cran_db: 3\n",     file = fname, append = TRUE)
    cat("r2u_directory: /var/local/r2u/\n", file = fname, append = TRUE)
    cat("package_cache: /var/local/r2u/cache\n", file = fname, append = TRUE)
    cat("build_directory: /var/local/r2u/build\n",file = fname, append = TRUE)
    cat("deb_directory: /var/local/r2u/ubuntu/pool\n",file = fname, append = TRUE)
    cat("build_container: eddelbuettel/r2u_build\n", file = fname, append = TRUE)

    if (!dir.exists("/var/local/r2u/cache"))       dir.create("/var/local/r2u/cache", recursive=TRUE)
    if (!dir.exists("/var/local/r2u/build"))       dir.create("/var/local/r2u/build", recursive=TRUE)
    if (!dir.exists("/var/local/r2u/ubuntu/pool")) dir.create("/var/local/r2u/ubuntu/pool", recursive=TRUE)
    if (.in.docker()) {
        if (!file.exists("/mnt/cache"))  file.symlink("/var/local/r2u/cache", "/mnt")
        if (!file.exists("/mnt/build"))  file.symlink("/var/local/r2u/build", "/mnt")
        if (!file.exists("/mnt/ubuntu")) file.symlink("/var/local/r2u/ubuntu", "/mnt")
    }
    for (file in c("blacklist.txt", "depends.dcf", "depends.noble.dcf", "runtimedepends.dcf")) {
        dstfile <- file.path(pkgdir, file)
        if (!file.exists(dstfile)) {
            srcfile <- file.path(system.file("configs", file, package="r2u"))
            file.copy(srcfile, dstfile)
        }
    }
}

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
        .debug_message("No package config dir for CRAN db\n")
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
        .debug_message("No package config dir for AP\n")
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
        .debug_message("No package config dir for BioC\n")
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
        .debug_message("No package config dir for build depends")
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
        .debug_message("No package config dir for blacklist")
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
        .debug_message("No package config dir for run-time depends")
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
            .pkgenv[["in_docker"]] <- as.logical(cfg[1, "in_docker"])
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
        } else {
            .debug_message("No config file\n")
            .pkgenv[["config_file"]] <- ""
            .pkgenv[["bioc_version"]] <- "3.20"
            .pkgenv[["package_cache"]] <- "/var/local/r2u/cache"
        }
        ## fallbacks, overriden when 'tgt' specified
        .pkgenv[["distribution"]] <- "24.04"
        .pkgenv[["distribution_name"]] <- "noble"
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
    bins <- c("apt", "dpkg", "date", "md5sum", "sha1sum", "sha256sum")
    if (isFALSE(.in.docker())) { 	# if not inside Docker already
        bins <- c("docker", bins)       # also check for docker binary
    }
    res <- Sys.which(bins)
    if (any(res=="")) {
        stop("Missing binaries for '", paste(names(res[res==""]), collapse=", "), "'.", call. = FALSE)
    }
    invisible()
}

.loadDB <- function(hrs = .pkgenv[["cache_age_hours_cran_db"]]) {
    if (is.na(match("db", names(.pkgenv)))) {
        .debug_message("Reading db\n")
        dbfile <- .defaultCRANDBFile()
        db <- NULL
        if (file.exists(dbfile) && !is.null(hrs)) {
            age <- as.numeric(difftime(Sys.time(), file.info(dbfile)$ctime, units="hours"))
            if (age < hrs) {
                db <- readRDS(dbfile)
                .debug_message("Cached db\n")
            }
        }
        if (is.null(db)) {
            .debug_message("Fresh db\n")
            db <- data.table(as.data.frame(tools::CRAN_package_db()))

            #message("Expanding CRAN database. One moment...")
            p <- tools::package_dependencies(db[, Package], db=db, recursive=TRUE)
            pp <- lapply(p, length)
            ppp <- sapply(pp, `[`)
            ## adjust out base packages
            adjpp <- lapply(p, \(x) length(setdiff(x, .basePkgs)))
            adjppp <- sapply(adjpp, `[`)
            np <- data.table(Package=names(ppp), ndep=ppp, adjdep=adjppp)
            db <- db[np, on="Package"]

            ## adjust out the base packages
            #baserevs <- tools::package_dependencies(.basePkgs, db=db, reverse=TRUE)
            #db[, adjdep := ndep]
            #for (br in names(baserevs)) db[Package %in% baserevs[[br]], adjdep := adjdep - 1]

            dbfile <- .defaultCRANDBFile(TRUE)
            if (dbfile != "") {
                saveRDS(db, dbfile)
                .debug_message("Written db\n")
            } else {
                .debug_message("Not writing db as no default dir\n")
            }
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
        ap <- NULL
        if (file.exists(apfile) && !is.null(hrs)) {
            if (as.numeric(difftime(Sys.time(), file.info(apfile)$ctime, units="hours")) < hrs) {
                ap <- readRDS(apfile)
                .debug_message("Cached ap\n")
            }
        }
        if (is.null(ap)) {
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
            ## when we run at GH we do not want / need ppm as it lags a day so switch to CRAN there
            ppmrepo <- "https://packagemanager.posit.co/all/__linux__/jammy/latest"
            ##cranrepo <- "https://cloud.r-project.org"
            ##aprepo <- if (nzchar(Sys.getenv("CI", ""))) ppmrepo else cranrepo
            aprepo <- ppmrepo
            apPPM <- data.table(ap="CRAN", as.data.frame(available.packages(repos=aprepo)))
            ap <- merge(apPPM, apBIOC, all=TRUE)

            ap[, deb := paste0("r-", tolower(ap), "-", tolower(Package))]

            apfile <- .defaultAPFile(TRUE)
            if (apfile != "") {
                saveRDS(ap, apfile)
                .debug_message("Written ap\n")
            } else {
                .debug_message("Not writing ap as no config dir\n")
            }
        }
        .pkgenv[["ap"]] <- data.table(as.data.frame(ap))
    } else {
        .debug_message("Have ap\n")
    }
}

.allBuilds <- function(tgt, pltfrm) {
    if (missing(tgt)) tgt <- .pkgenv[["distribution_name"]]
    if (missing(pltfrm)) pltfrm <- .platform()
    tfile <- tempfile(fileext=".rds")
    url <- file.path("https://r2u.stat.illinois.edu/ubuntu/pool/dists", tgt, "main/builds.rds")
    download.file(url, tfile, quiet=TRUE)
    B <- readRDS(tfile)
    unlink(tfile)
    B <- B[arch %in% c("all", pltfrm), ]
    B
}

.loadBuilds <- function(tgt, pltfrm) {
    if (missing(tgt)) tgt <- .pkgenv[["distribution_name"]]
    if (missing(pltfrm)) pltfrm <- .platform()
    dd <- file.path(.pkgenv[["deb_directory"]], "dists", tgt, "main")
    if (isFALSE(.pkgenv[["in_docker"]]) && isTRUE(nzchar(dd)) && dir.exists(dd)) {	## this is specific to local build with the local pool of builds
        ## cannot read builds.rds which only exists for noble
        cwd <- getwd()
        setwd(dd)
        fls <- list.files(".", pattern="\\.deb$", full.names=FALSE)
        flsse <- tools::file_path_sans_ext(fls)
        arch <-   gsub(".*_(all|arm64|amd64)$", "\\1", flsse)
        pkgver <- gsub("-\\d+.ca(20|22|24)04.\\d+_(all|arm64|amd64)$", "", flsse)
        tgt <- gsub(".*-\\d+.ca(\\d{4}).\\d+_.*", "\\1", flsse)
        B <- data.table(name=fls, pkgver=pkgver, arch=arch, file.info(fls), tgt=tgt)
        B <- B[arch %in% c("all", pltfrm), ]
        .pkgenv[["builds"]] <- B
        setwd(cwd)
    } else if (nzchar(Sys.getenv("CI", ""))) { 						## this is specific to the arm64 build at GH
        ## get packages already Built
        #B <- data.table::fread(cmd=r"(links -dump https://r2u.stat.illinois.edu/ubuntu/pool/dists/noble/main/| awk '/r-.*arm64.deb/ { print $1 "," $2 " "$3 "," $4 }')", col.names=c("file","date","size"))
        #B[, version := gsub(".*_(.*)_arm64.deb", "\\1", file), by=file]
        #B[, r2u := grepl("ca2404", version), by=file]  # needed ?
        #B[, ver := gsub("(.*)-(\\d\\.ca\\d{4}\\.\\d)$", "\\1", version)][] # upstream
        #B[, pkgver := gsub("(.*)-(\\d\\.ca\\d{4}\\.\\d)_(arm64|amd64|all).deb$", "\\1", file)]
        B <- .allBuilds(tgt)
        B <- B[arch == pltfrm, ]
        .pkgenv[["builds"]] <- B
    } else {
        .pkgenv[["builds"]] <- NULL
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
