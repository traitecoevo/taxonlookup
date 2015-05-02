##' Lookup table relating plant genera, families and orders.  Data
##' persists across package installations.
##'
##' @title Plant lookup table
##' @param version Version number.  The default will load the most
##' recent version on your computer or the most recent version known
##' to the package if you have never downloaded the data before.
##' @export
plant_lookup <- function(version=plant_lookup_version_current()) {
  if (is.null(version)) {
    version <- plant_lookup_version_current(FALSE)
  }
  st <- plant_lookup_storr()
  if (st$exists(version)) {
    st$get(version)
  } else {
    d <- plant_lookup_fetch(version)
    st$set(version, d)
    d
  }
}

##' @export
##' @rdname plant_lookup
##' @param all test against all version known to the package?
plant_lookup_versions <- function(all=FALSE) {
  if (all) {
    c("0.1.0")
  } else {
    re <- "^plant_lookup_(.+).csv$"
    sub(re, "\\1", dir(plant_lookup_path(), re))
  }
}

##' @export
##' @rdname plant_lookup
plant_lookup_version_current <- function(all=FALSE) {
  if (all) {
    ## TODO: This *should* ping /latest I think.
    last(plant_lookup_versions(TRUE))
  } else {
    v <- plant_lookup_storr()$list()
    if (length(v) == 0L) {
      plant_lookup_version_current(TRUE)
    } else {
      last(sort(numeric_version(v)))
    }
  }
}

##' @importFrom rappdirs user_data_dir
plant_lookup_path <- function(version=NULL) {
  path <- rappdirs::user_data_dir(.packageName)
  if (is.null(version)) {
    path
  } else {
    file.path(path, sprintf("plant_lookup_%s.csv", version))
  }
}

plant_lookup_storr <- function() {
  storr::storr_rds(rappdirs::user_data_dir(.packageName),
                   default_namespace="plant_lookup")
}

plant_lookup_delete <- function(version) {
  plant_lookup_storr()$del(version)
}

plant_lookup_url <- function(version) {
  prefix <- "https://github.com/wcornwell/TaxonLookup/releases/download/v"
  paste0(prefix, version, "/plant_lookup.csv")
}

##' @importFrom downloader download
plant_lookup_fetch <- function(version) {
  dest <- tempfile()
  url <- plant_lookup_url(version)
  downloader::download(url, dest)
  ## Detecting error here is surprisingly hard:
  if (!file.exists(dest)) {
    stop("Download failed")
  } else {
    first <- readLines(dest, n=1, warn=FALSE)
    if (grepl("error", first, fixed=TRUE) ||
        grepl("DOCTYPE", first, fixed=TRUE)) {
      file.remove(dest)
      stop("Download failed: ", first)
    }
  }
  read.csv(dest, stringsAsFactors=FALSE)
}
