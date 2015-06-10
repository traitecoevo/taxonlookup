##' Lookup table relating plant genera, families and orders along with
##' number of species in each genus.  Data persists across package
##' installations.
##'
##' The data within this lookup table comes from two sources:
##'
##' 1. The Plant List v1.1. (http://www.theplantlist.org/) for
##' accepted genera to families and species richness within each
##' genera.  Note that we do not consider hybrids (e.g. Genus X
##' species) as distinct species for this count while the plant list summary
##' statistics do, so the the counts from this package will not line up exactly
##' with the ones on the TPL website.
##'
##' 2. APWeb (http://www.mobot.org/MOBOT/research/APweb/) for family-level
##' synonymies and family-to-order for all vascular plant families.
##' Note that there is not currently order-level information available for Bryophytes.
##'
##' These data are then currated--we correct some spelling
##' errors, special character issues, genera listed in multiple families, family-level synonomy,
##' and other issues that arise in assembling a resources like this.  Details of the curration
##' are at https://github.com/wcornwell/taxonlookup
##'
##' @title Plant lookup table
##' @param version Version number.  The default will load the most
##' recent version on your computer or the most recent version known
##' to the package if you have never downloaded the data before.  With
##' \code{plant_lookup_delete}, omitting the versions deletes
##' \emph{all} data sets.
##' @param include_counts Logical: Include a column of number of
##' "accepted" species within each genus counts as
##' \code{number.of.species}.
##' @param family.tax = the value "ap.web" will return the family names from apweb
##' otherwise the lookup will include the family names from the plant list.
##' Currently there are 8 family names that differ between the two sources.
##' \code{number.of.species}.
##' @export
##' @examples
##' #
##' # see the format of the resource
##' head(plant_lookup())
##'
##' # or with number of species in each genus.
##'
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
##'
plant_lookup <- function(version=plant_lookup_version_current(),
                         include_counts=FALSE,family.tax="apweb") {
    d <- plant_lookup_storr()$get(version)
    if (!include_counts) {
      d <- d[names(d) != "number.of.species"]
    }
    if (family.tax=="apweb") {
      d$family<-d$apweb.family
      d <- d[names(d) != "apweb.family"]
    }
    else{
      d <- d[names(d) != "apweb.family"]
    }
    d
  }
data <- function(...) {
  plant_lookup(...)
}

##' @export
##' @rdname plant_lookup
##' @param type Type of version to return: options are "local"
##' (versions installed locally) or "github" (versions available on
##' github).  With any luck, "github" is a superset of "local".
plant_lookup_versions <- function(type="local") {
  v <- switch(
    type,
    github=storr::github_release_versions(paste0("wcornwell/", .packageName)),
    local=plant_lookup_storr()$list(),
    stop("Unknown type ", type))
  v
}

##' @export
##' @rdname plant_lookup
plant_lookup_version_current <- function(type="local") {
  ## TODO: This *should* ping /latest I think.
  ## Manually add data if data and package versions are out of line
  if (type == "local" && length(plant_lookup_versions(type)) == 0L) {
    type <- "github"
  }
  last(plant_lookup_versions(type))
}

##' @importFrom storr storr
##' @importFrom httr GET
plant_lookup_env <- new.env(parent=emptyenv())
plant_lookup_storr <- function() {
  ## Probably this pattern of env/lookup should be done with an
  ## environment storr (repeated in baad.data)
  if (is.null(plant_lookup_env$storr)) {
    hook <- storr::fetch_hook_download(plant_lookup_url, read_csv)
    st <- storr::driver_rds(plant_lookup_path())
    dr <- storr::driver_external(st, hook)
    plant_lookup_env$storr <- storr::storr(dr, "plant_lookup")
  }
  plant_lookup_env$storr
}

##' @importFrom rappdirs user_data_dir
plant_lookup_path <- function() {
  rappdirs::user_data_dir(.packageName)
}

##' @export
##' @rdname plant_lookup
plant_lookup_delete <- function(version=NULL) {
  if (is.null(version)) {
    unlink(plant_lookup_path(), recursive=TRUE)
  } else {
    plant_lookup_storr()$del(version)
  }
}

## The namespace argument is
plant_lookup_url <- function(version, namespace) {
  prefix <- "https://github.com/wcornwell/TaxonLookup/releases/download/v"
  paste0(prefix, version, "/plant_lookup.csv")
}

read_csv <- function(...) {
  read.csv(..., stringsAsFactors=FALSE)
}
