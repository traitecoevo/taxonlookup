##' @importFrom downloader download
download_maybe <- function(url, dest, refetch=FALSE, path=".") {
  if (refetch || !file.exists(dest)) {
    dir.create(dirname(dest), FALSE, TRUE)
    downloader::download(url, dest)
  }
  invisible(dest)
}
