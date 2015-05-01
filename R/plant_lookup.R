##' Lookup table relating plant genera, families and orders
##'
##' @docType data
##' @keywords datasets
##' @name plant_lookup
##' @usage data(plant_lookup)
##' @format A data.frame with three columns and many rows
NULL

get_plant_lookup <- function() {
  plant_lookup <- NULL
  data("plant_lookup", package=.packageName, envir=environment())
  plant_lookup
}

##' Build a lookup table for a set of species
##' @title Build a lookup table for a set of species
##' @param species_list Character vector of species names
##' @param lookup_table A lookup table, or by default \code{\link{plant_lookup}}
##' @param genus_column The column within \code{lookup_table} that
##' corresponds to genus.  By default this is \code{"genus"}, which is
##' the correct name for \code{\link{plant_lookup}}.
##' @param missing_action How to behave when there are genera in the
##' \code{species_list} that are not found in the lookup table.
##' \code{"drop"} (the default) generates a table without these
##' genera, \code{"NA"} will leave the non-genus taxonomic levels as
##' missing values and \code{error} will throw an error.
##' @export
lookup_table <- function(species_list, lookup_table=NULL,
                         genus_column="genus",
                         missing_action=c("drop", "NA", "error")) {
  if (is.null(lookup_table)) {
    lookup_table <- get_plant_lookup()
  }

  missing_action <- match.arg(missing_action)

  genera <- unique(split_genus(species_list))
  i <- match(genera, lookup_table[[genus_column]])

  if (any(is.na(i))) {
    if (missing_action == "drop") {
      i <- i[!is.na(i)]
    } else if (missing_action == "error") {
      stop("Missing genera: ", pastec(genera[is.na(i)]))
    }
  }

  ret <- lookup_table[i, ]
  if (any(is.na(i)) && missing_action == "NA") {
    ret[[genus_column]][is.na(i)] <- genera[is.na(i)]
  }

  rownames(ret) <- NULL

  ret
}
