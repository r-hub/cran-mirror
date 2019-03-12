

rsync_mirror <- function() {
  system("rsync -rtlzv --delete mirrors.nic.cz::CRAN /cran/cran")
  system("find /cran/cran -type d -exec chmod +x \\{\\} \\;")
  system("chmod -R +r /cran/cran")
}

mkdirp <- function(x) {
  dir.create(x, showWarnings = FALSE, recursive = TRUE)
}

`%||%` <- function(l, r) if (is.null(l)) r else l

is_na1 <- function(x) {
  identical(x, NA_character_) || identical(x, NA_integer_) ||
    identical(x, NA_real_) || identical(x, NA_complex_) ||
    identical(x, NA)
}

`%|NA|%` <- function(l, r) if (is_na1(l)) r else l

get_ext <- function(pkgdir) {
  if (grepl("windows", pkgdir)) {
    ".zip"
  } else if (grepl("macos", pkgdir)) {
    ".tgz"
  } else {
    ".tar.gz"
  }
}

get_pkgs <- function(pkgdir) {
  pkgs <- tryCatch(
    suppressWarnings(readRDS(file.path(pkgdir, "PACKAGES.rds"))),
    error = function(err) NULL)

  pkgs <- pkgs %||% tryCatch(
    suppressWarnings(read.dcf(file.path(pkgdir, "PACKAGES.gz"))),
    error = function(err) NULL)

  pkgs <- pkgs %||% tryCatch(
    suppressWarnings(read.dcf(file.path(pkgdir, "PACKAGES"))),
    error = function(err) NULL)

  if (is.null(pkgs)) return(pkgs)

  ext <- get_ext(pkgdir)
  files <- paste0(pkgs[, "Package"], "_", pkgs[, "Version"], ext)

  if ("File" %in% colnames(pkgs)) {
    wh <- !is.na(pkgs[, "File"])
    files[wh] <- pkgs[wh, "File"]
  }

  if ("Path" %in% colnames(pkgs)) {
    wh <- !is.na(pkgs[, "Path"])
    files[wh] <- file.path(pkgs[wh, "Path"], files[wh])
  }

  files
}

get_desc_tar <- function(f, p) {
  cmd <- sprintf(
    "zcat \"%s\" | head -c 200000 | tar -xOf - %s/DESCRIPTION 2>/dev/null",
    f, p)
  tryCatch(
    system(cmd, intern = TRUE),
    warning = function(e) {
      system(sprintf("tar -xOf \"%s\" %s/DESCRIPTION", f, p), intern = TRUE)
    })
}

get_desc_zip <- function(f, p) {
  cmd <- sprintf("unzip -p \"%s\" %s/DESCRIPTION", f, p)
  system(cmd, intern = TRUE)
}

get_sysreqs <- function(files) {
  pkgs <- sub("_.*$", "", basename(files))
  mapply(files, pkgs, USE.NAMES = FALSE, FUN = function(f, p) {
    d <- if (grepl("\\.zip$", f)) get_desc_zip(f, p) else get_desc_tar(f, p)
    desc::desc(text = d)$get("SystemRequirements")[[1]] %|NA|% ""
  })
}

update_metadata <- function(d, update_all = FALSE) {
  message("Creating metadata for ", d)
  pkgdir <- file.path("/cran/cran/", d)
  output <- file.path("/cran/metadata", d, "METADATA2.gz")
  mkdirp(dirname(output))

  pkgs <- get_pkgs(pkgdir)
  if (is.null(pkgs)) {
    message("Cannot update ", d, ", cannot load PACKAGES file. :(")
    return()
  }

  if (!update_all && file.exists(output)) {
    ex <- read.csv(gzfile(output), header = TRUE, stringsAsFactors = FALSE)

    ## Remove the files that do not exist in the new DB
    ex <- ex[ex[,1] %in% pkgs, ]

    ## These are new files in the DB
    new <- setdiff(pkgs, ex[,1])

    ## Updated files in the DB, remove these from ex, they need update
    new <- unique(c(new, pkgs[file.mtime(file.path(pkgdir, pkgs)) >
                              file.mtime(output)]))
    ex <- ex[! ex[,1] %in% new, ]

  } else {
    ex <- data.frame(stringsAsFactors = FALSE, file = character(),
                     size = character(), sha = character())
    new <- pkgs
  }

  ## Only keep the ones that actually exist
  new <- new[file.exists(file.path(pkgdir, new))]

  if (length(new)) {
    ## Add new files
    new_size <- file.size(file.path(pkgdir, new))
    cat(file.path(pkgdir, new), file = tmp <- tempfile(), sep = "\n")
    new_chk <- system(sprintf("shasum -a 256 $(cat \"%s\")", tmp),
                      intern = TRUE)
    sysreqs <- get_sysreqs(file.path(pkgdir, new))
    sysreqs <- gsub("\r?\n[ ]*", " ", sysreqs)

    newdf <- data.frame(
      stringsAsFactors = FALSE,
      file = new,
      size = new_size,
      sha = sub("\\s+.*$", "", new_chk),
      sysreqs = sysreqs)

  } else {
    newdf <- NULL
  }

  all <- rbind(newdf, ex)
  all <- all[ order(all[,1]), ]

  outcon <- gzcon(file(output, "wb"))
  write.csv(all, outcon, row.names = FALSE)
  close(outcon)
}

update_package_dirs <- function(update_all = FALSE) {
  wd <- getwd()
  setwd("/cran/cran")
  on.exit(setwd(wd), add = TRUE)
  dirs <- unique(normalizePath(
    dirname(dir("/cran/cran/", pattern = "PACKAGES.*", recursive=TRUE))
  ))

  dirs <- sub("^/cran/cran/", "", dirs)
  for (d in dirs) update_metadata(d, update_all = update_all)
}

main <- function() {
  rsync_mirror()
  update_package_dirs()
}

## We do not run this if the script is source()-d.
if (is.null(sys.calls())) main()
