##' Augment a lookup table with plant higher order data, from
##' http://datadryad.org/resource/doi:10.5061/dryad.63q27
##' @title Add higher order taxonomy
##' @param lookup A lookup table (by default \code{plant_lookup()})
##' @param order_column The column within \code{lookup} that
##' corresponds to taxonomic order.
##' @export
add_higher_order <- function(lookup=plant_lookup(), order_column="order") {
  hot <- higher_order_taxonomy[lookup[[order_column]], ]
  rownames(hot) <- NULL
  hot[is.na(hot)] <- ""
  cbind(lookup, hot)
}
