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
##' and other issues that arise in assembling a resources like this.  Details of the curation
##' are at https://github.com/wcornwell/taxonlookup
##'
##' @title Plant taxonomy lookup table
##'
##' @param version Version number.  The default will load the most
##'   recent version on your computer or the most recent version known
##'   to the package if you have never downloaded the data before.
##'   With \code{plant_lookup_del}, specifying \code{version=NULL}
##'   will delete \emph{all} data sets.
##'
##' @param include_counts Logical: Include a column of number of
##'   "accepted" species within each genus counts as
##'   \code{number.of.species}.
##'
##' @param family.tax the value "ap.web" will return the family
##'   names from apweb otherwise the lookup will include the family
##'   names from the plant list.  Currently there are 8 family names
##'   that differ between the two sources (e.g., Compositae in the plant list
##'   versus Asteraceae in ap.web)
##'
##' @export
##' @import storr
##' @examples
##' #
##' # see the format of the resource
##' #
##' head(plant_lookup())
##' #
##' # or with number of species in each genus.
##' #
##' head(plant_lookup(include_counts = TRUE))
##' #
##' # load the data.frame into memory
##' #
##' pl<-plant_lookup(include_counts = TRUE)
##' #
##' # return family, order, and number of species for the genus Eucalyptus
##' #
##' pl$family[pl$genus=="Eucalyptus"]
##' pl$order[pl$genus=="Eucalyptus"]
##' pl$number.of.species[pl$genus=="Eucalyptus"]
##' #
##' # find the number of accepted species within the Myrtaceae
##' #
##' sum(pl$number.of.species[pl$family=="Myrtaceae"])
plant_lookup <- function(version=NULL, include_counts=FALSE, family.tax="apweb") {
  d <- plant_lookup_get(version)
  if (!include_counts) {
    d <- d[names(d) != "number.of.species"]
  }
  if (family.tax == "apweb") {
    d$family <- d$apweb.family
  }
  d[names(d) != "apweb.family"]
}

## This one is the important part; it defines the three core bits of
## information we need;
##   1. the repository name (wcornwell/taxonlookup)
##   2. the file to download (plant_lookup.csv)
##   3. the function to read the file, given a filename (read_csv)
plant_lookup_info <- function() {
  github_release_storr_info("wcornwell/taxonlookup",
                            "plant_lookup.csv",
                            read_csv)
}

## Below here are wrappers around the storr functions but with our
## information object.  We could actually save plant_lookup_info() as
## an *object* in the package, but I prefer this approach.
plant_lookup_get <- function(version=NULL) {
  github_release_storr_get(plant_lookup_info(), version)
}

##' @export
##' @rdname plant_lookup
##' @param type Type of version to return: options are "local"
##'   (versions installed locally) or "github" (versions available on
##'   github).  With any luck, "github" is a superset of "local".  For
##'   \code{plant_lookup_version_current}, if "local" is given, but there
##'   are no local versions, then we do check for the most recent
##'   github version.
plant_lookup_versions <- function(type="local") {
  github_release_storr_versions(plant_lookup_info(), type)
}

##' @export
##' @rdname plant_lookup
plant_lookup_version_current <- function(type="local") {
  github_release_storr_version_current(plant_lookup_info(), type)
}

##' @export
##' @rdname plant_lookup
plant_lookup_del <- function(version) {
  github_release_storr_del(plant_lookup_info(), version)
}

read_csv <- function(...) {
  read.csv(..., stringsAsFactors=FALSE)
}
