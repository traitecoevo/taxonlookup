context("higher_order")

test_that("higher_order", {
  lookup <- plant_lookup(path=tempfile())
  ho <- add_higher_order(lookup)
  expect_that(length(ho$genus), equals(length(unique(ho$genus))))
})

