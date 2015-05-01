context("plant_lookup")

test_that("table sane", {
  expect_that(ncol(plant_lookup), equals(3L))
  expect_that(plant_lookup, is_a("data.frame"))
  expect_that(names(plant_lookup), equals(c("genus", "family", "order")))
  expect_that(any(is.na(plant_lookup)), is_false())
  expect_that(any(plant_lookup == ""), is_false())
})
