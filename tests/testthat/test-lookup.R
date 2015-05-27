context("lookup")

test_that("lookup_table", {
  lookup <- plant_lookup()
  set.seed(1)
  sp <- sample(lookup$genus, 20)
  dat <- lookup_table(sp, lookup)

  expect_that(nrow(dat), equals(length(sp)))
  expect_that(rownames(dat), equals(as.character(seq_len(nrow(dat)))))

  ## with extra things:
  sp2 <- sample(c(sp, "missing1", "missing2"))

  ## Default is drop:
  dat <- lookup_table(sp2, lookup)
  expect_that(nrow(dat), equals(length(sp)))
  expect_that(dat$genus, equals(sp2[!grepl("^missing", sp2)]))

  ## Or we can error:
  expect_that(lookup_table(sp2, lookup, missing_action="error"),
              throws_error("Missing genera: missing"))

  ## Or we can generate unknowns:
  dat <- lookup_table(sp2, lookup, missing_action="NA")
  expect_that(nrow(dat), equals(length(sp2)))
  expect_that(dat$genus, equals(sp2))

  expect_that(dat$family[grepl("^missing", sp2)],
              equals(rep(NA_character_, 2)))

  ## Automatically detect the species table:
  dat2 <- lookup_table(sp2, missing_action="NA")
  expect_that(dat2, is_identical_to(dat))

  ## Filtering.
  sp3 <- sample(rep(sp, 2))
  dat3 <- lookup_table(sp3)
  expect_that(nrow(dat3), equals(length(sp)))
  expect_that(dat3$genus, equals(unique(sp3)))

  ## by species:
  pt2 <- sample(c("foo", "bar", "baz"), length(sp3), replace=TRUE)
  sp4 <- unique(paste(sp3, pt2))
  dat4 <- lookup_table(sp4, by_species=TRUE)
  expect_that(rownames(dat4), equals(sp4))
  expect_that(dat4$genus, equals(split_genus(sp4)))

  sp5 <- sample(c(sp4, "missing1", "missing2"))
  ## drop missing
  dat5 <- lookup_table(sp5, by_species=TRUE)
  expect_that(any(is.na(dat5$family)), is_false())

  dat5 <- lookup_table(sp5, by_species=TRUE, missing_action="NA")
  expect_that(any(is.na(dat5$family)), is_true())
})

test_that("all versions", {
  versions <- plant_lookup_versions("github")
  for (v in versions) {
    d <- plant_lookup(v)
    expect_that(d, is_a("data.frame"))
  }
  expect_that(plant_lookup_versions("local"), equals(versions))
})
