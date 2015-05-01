context("plant_lookup")

## Need to do something nice here with testing?
test_that("table sane", {
  lookup <- plant_lookup()
  expect_that(ncol(lookup), equals(4L))
  expect_that(lookup, is_a("data.frame"))
  expect_that(names(lookup),
              equals(c("genus", "family", "order", "group")))
  expect_that(any(is.na(lookup)), is_false())
  expect_that(any(lookup == ""), is_false())
  expect_that(any(duplicated(lookup$genus)), is_false())
})
