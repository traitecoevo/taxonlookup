## 'path' is the root to inst/extdata
## within that we'll have 'original' and then at the root the actual
## data files

## Fetch data from the original locations; this is to bootstrap the
## package and to connect to the original sources.
download_zae <- function(path="inst/extdata") {
  prefix <- "http://datadryad.org/bitstream/handle/10255/"
  suffix <- "dryad.55304/Spermatophyta_Genera.csv?sequence=2"
  url <- paste0(prefix, suffix)
  download_maybe(url, file.path(path, "original", "Spermatophyta_Genera.csv"))
}

patch_zae <- function(path="inst/extdata") {
  lookup <- read.csv(file.path(path, "original", "Spermatophyta_Genera.csv"),
                     stringsAsFactors=FALSE)
  names(lookup)[1] <- "genus"
  lookup <- lookup[c("genus", "family", "order")]

  lookup$family[lookup$genus == "Peltanthera"] <- "Gesneriaceae"
  lookup$family[lookup$genus == "Brachynema" ] <- "Olacaceae"
  write.csv(lookup, file.path(path, "genus_order_lookup_zae.csv"),
            row.names=FALSE)
}

##' @importFrom downloader download
download_fae <- function(path="inst/extdata") {
  url <-
    "https://raw.githubusercontent.com/richfitz/wood/master/data/genus_order_lookup_extra.csv"
  download_maybe(url, file.path(path, "genus_order_lookup_fae.csv"))
}

relationalise <- function(d) {
  pairs <- c(family = "genus",
             order  = "family")

  d <- combine(d)

  dat <- setNames(vector("list", length(pairs)), names(pairs))

  for (i in seq_along(pairs)) {
    parent <- names(pairs)[[i]]
    child  <- pairs[[i]]

    dsub <- unique(d[c(parent, child)])
    dsub[dsub == ""] <- NA
    dsub <- dsub[order(dsub[[parent]], dsub[[child]]), ]
    rownames(dsub) <- NULL
    j <- complete.cases(dsub)

    kids <- dsub[j, child]
    dups <- kids[duplicated(kids)]
    if (length(dups)) {
      warning("Ambiguously resolved child groups: ",
              paste(dups, collapse=", "))
    }

    dat[[i]] <- dsub
  }
  dat
}
