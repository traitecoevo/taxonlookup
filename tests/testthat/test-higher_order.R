context("higher_order")

## TODO: this should probably work with a temporary directory, rather
## than the real data.

test_that("higher_order", {
  ho<-add_higher_order()
  expect_that(length(ho$genus)== length(unique(ho$genus)),is_true())
})

