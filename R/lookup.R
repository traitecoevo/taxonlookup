##' Build a lookup table for a set of species, connecting the species names to plant genera, families and orders
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
##' @title Build a family and order lookup table for a set of species
##' @param species_list Character vector of species bionomials  Genus and species may be seperated by  " "
##' or "_"
##' @param lookup_table Any higher taxonomy lookup table, but by default \code{\link{plant_lookup}}
##' @param genus_column The column within \code{lookup_table} that
##' corresponds to genus.  By default this is \code{"genus"}, which is
##' the correct name for \code{\link{plant_lookup}}.
##' @param missing_action How to behave when there are genera in the
##' \code{species_list} that are not found in the lookup table.
##' \code{"drop"} (the default) generates a table without these
##' genera, \code{"NA"} will leave the non-genus taxonomic levels as
##' missing values and \code{error} will throw an error.
##' @param by_species If \code{TRUE}, then return a larger data frame
##' with one row per species and with species as row names.
##' @export
##' @examples
##' lookup_table("Pinus_ponderosa")
##' #
##' # or with a space
##' #
##' lookup_table("Pinus ponderosa")
##' #
##' #
##' # control how you want the function to handle non-matches
##' #
##' lookup_table(c("Pinus ponderosa","Neitheragenus noraspecies"))
##' #
##' lookup_table(c("Pinus ponderosa","Neitheragenus noraspecies"),missing_action="NA")
##'
lookup_table <- function(species_list, lookup_table=NULL,
                         genus_column="genus",
                         missing_action=c("drop", "NA", "error"),
                         by_species=FALSE) {
  if (is.null(lookup_table)) {
    lookup_table <- plant_lookup()
  }

  missing_action <- match.arg(missing_action)

  genus_list <- split_genus(species_list)
  genera <- unique(genus_list)
  i <- match(genera, lookup_table[[genus_column]])

  if (any(is.na(i))) {
    if (missing_action == "drop") {
      genera <- genera[!is.na(i)]
      i <- i[!is.na(i)]
    } else if (missing_action == "error") {
      stop("Missing genera: ", pastec(genera[is.na(i)]))
    }
  }

  ret <- lookup_table[i, ]
  if (any(is.na(i)) && missing_action == "NA") {
    ret[[genus_column]][is.na(i)] <- genera[is.na(i)]
  }

  if (by_species) {
    j <- match(genus_list, genera)
    if (missing_action == "drop") {
      species_list <- species_list[!is.na(j)]
      j <- j[!is.na(j)]
    }
    ret <- ret[j, ]
    rownames(ret) <- species_list
  } else {
    rownames(ret) <- NULL
  }

  ret
}
