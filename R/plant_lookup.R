##' Lookup table relating plant genera, families and orders along with
##' number of species in each genus.  Data persists across package
##' installations.
##'
##' The data for this lookup primarily comes from two sources:
##'
##' 1. The Plant List v1.1. (http://www.theplantlist.org/) for
##' accepted genera to families and species richness within each
##' genera.  Note that we do not consider hybrids (e.g. Genus x
##' species) as species for this count while the plant list summary
##' statistics do, so the the counts from this package will not line up exactly
##' with the ones on the TPL website.
##'
##' 2. APWeb (http://www.mobot.org/MOBOT/research/APweb/) for family
##' level synonymies and family-to-order for all vascular plant families.
##' Note that there is not currently order-level information available for Bryophytes.
##'
##' 3. We correct some spelling
##' errors, special character issues, genera listed in multiple families,
##' and a few other errors from The Plant List.
##'
##' @title Plant lookup table
##' @param version Version number.  The default will load the most
##' recent version on your computer or the most recent version known
##' to the package if you have never downloaded the data before.
##' @param include_counts Logical: Include a column of genus counts as
##' \code{number.of.species}.
##' @export
##' @examples
##' #
##' # see the format of the resource
##' head(plant_lookup(include_counts = TRUE))
##' #
##' # load the data.frame into memory
##' pl<-plant_lookup(include_counts = TRUE)
##' #
##' # return family, order, and number of species for the genus Eucalyptus
##' pl$family[pl$genus=="Eucalyptus"]
##' pl$order[pl$genus=="Eucalyptus"]
##' pl$number.of.species[pl$genus=="Eucalyptus"]
##' #
##' # find the number of accepted species within the Myrtaceae
##' sum(pl$number.of.species[pl$family=="Myrtaceae"])
##'
plant_lookup <- function(version=plant_lookup_version_current(),
                         include_counts=FALSE) {
  if (is.null(version)) {
    version <- plant_lookup_version_current(FALSE)
  }

  st <- plant_lookup_storr()
  if (st$exists(version)) {
    d <- st$get(version)
  } else {
    d <- plant_lookup_fetch(version)
    st$set(version, d)
  }

  if (!include_counts) {
    d <- d[names(d) != "number.of.species"]
  }

  d
}

##' @export
##' @rdname plant_lookup
##' @param all test against all version known to the package?
plant_lookup_versions <- function(all=FALSE) {
  if (all) {
    c("0.1.0", "0.1.1","0.1.2","0.1.3","0.1.4","0.2.0")
  } else {
    plant_lookup_storr()$list()
  }
}

##' @export
##' @rdname plant_lookup
plant_lookup_version_current <- function(all=FALSE) {
  if (all) {
    ## TODO: This *should* ping /latest I think.
    ## Manually add data if data and package versions are out of line
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
  #TODO: add dataset version as attribute
  read.csv(dest, stringsAsFactors=FALSE)
}
