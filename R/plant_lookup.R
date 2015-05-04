##' Lookup table relating plant genera, families and orders along with number of species in each genus.  Data
##' persists across package installations.
##'
##' The data for this lookup primarily comes from three sources:
##'
##' 1. The Plant List v1.1. (http://www.theplantlist.org/) for accepted genera to families and species richness within each genera.  Note that we do not consider hybrids (e.g. Genus x species) as species for this count while the plant list summary statistics do, so the counts will not line up exactly.
##'
##' 2. APWeb (http://www.mobot.org/MOBOT/research/APweb/) for family level synonymies and family to order
##'
##' 3. A higher-level taxonomy lookup (http://datadryad.org/resource/doi:10.5061/dryad.63q27.2/1.1) compiled by Dave Tank and colleagues
##'
##'To complete the family to order data (beyond the taxonomic scope of APWeb) we add a few additional family to order mappings for non-seed plants (mostly ferns).  We also correct some spelling errors, special character issues, and other errors from The Plant List.
##'
##' @title Plant lookup table
##' @param version Version number.  The default will load the most
##' recent version on your computer or the most recent version known
##' to the package if you have never downloaded the data before.
##' @export
##' @examples
##' #
##' # see the format of the resource
##' head(plant_lookup())
##' #
##' # load the data.frame into memory
##' pl<-plant_lookup()
##' #
##' # return family, order, and number of species for the genus Eucalyptus
##' pl$family[pl$genus=="Eucalyptus"]
##' pl$order[pl$genus=="Eucalyptus"]
##' pl$number.of.species[pl$genus=="Eucalyptus"]
##' #
##' # find the number of species in Asteraceae
##' sum(pl$number.of.species[pl$family=="Asteraceae"])
##'
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
    c("0.1.0", "0.1.1","0.1.2","0.1.3","0.1.4")
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
