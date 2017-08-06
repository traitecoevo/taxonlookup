context("plant_lookup")

## Need to do something nice here with testing?
test_that("table sane", {
  path <- tempfile()
  lookup <- plant_lookup(path=path)
  expect_that(ncol(lookup), equals(4L))
  expect_that(lookup, is_a("data.frame"))
  expect_that(names(lookup),
              equals(c("genus", "family", "order", "group")))
  expect_that(any(is.na(lookup)), is_false())
  expect_that(any(lookup == ""), is_false())
  expect_that(any(duplicated(lookup$genus)), is_false())

  lookup <- plant_lookup(include_counts=TRUE, path=path)
  expect_that(ncol(lookup), equals(6L))
  expect_that(lookup, is_a("data.frame"))
  expect_that(any(is.na(lookup)), is_false())
  expect_that(any(lookup == ""), is_false())
  expect_that(any(duplicated(lookup$genus)), is_false())
  expect_is(plant_lookup_version_current(),"character")
  only_corn<-subset(lookup,lookup$genus=="Zea")
  expect_true(only_corn$family[1]=="Poaceae")
  expect_true(only_corn$group[1]=="Angiosperms")
})
