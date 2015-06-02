##' Augment the genus-family-order lookup table with plant higher taxa data, from
##' http://datadryad.org/resource/doi:10.5061/dryad.63q27
##'
##' Data for the higher-level taxonomy lookup (http://datadryad.org/resource/doi:10.5061/dryad.63q27.2/1.1) compiled by Dave Tank and colleagues
##'
##' Because of the currently non-nested structure of higher clade information for plants,
##' the format of the lookup is also not nested.
##' In the lookup the higher nodes are columns within the data.frame.
##' If a genus is a descendent of a particular node, the row for that genus repeats
##' the node name (which is also the column name).  If a genus is not a descendent of that particular node, the cell is left blank.
##'
##' @title Add higher order taxonomy
##' @param lookup A lookup table (by default \code{plant_lookup()})
##' @param order_column The column within \code{lookup} that
##' corresponds to taxonomic order.
##' @export
##' @examples
##'
##' ##' # see the format of the resource
##' head(add_higher_order())
##' #
##' # load the data.frame into memory
##' ho<-add_higher_order()
##' #
##' # return Rosid orders
##' unique(ho$order[ho$Rosidae=="Rosidae"])
##' #
##' # find the number of Conifer species in the world
##' sum(ho$number.of.species[ho$Coniferae=="Coniferae"])
##'
add_higher_order <- function(lookup=plant_lookup(include_counts=TRUE), order_column="order") {
  hot <- higher_order_taxonomy[lookup[[order_column]], ]
  rownames(hot) <- NULL
  hot[is.na(hot)] <- ""
  cbind(lookup, hot)
}
