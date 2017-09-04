context("plant_lookup")

## Need to do something nice here with testing?
test_that("table sane", {
  path <- tempfile()
  lookup <- plant_lookup(path=path)
  expect_equal(ncol(lookup), 4L)
  expect_is(lookup, "data.frame")
  expect_equal(names(lookup),
              c("genus", "family", "order", "group"))
  expect_false(any(is.na(lookup)))
  expect_false(any(lookup == ""))
  expect_false(any(duplicated(lookup$genus)))

  lookup <- plant_lookup(include_counts=TRUE, path=path)
  expect_that(ncol(lookup), equals(6L))
  expect_is(lookup, "data.frame")
  expect_false(any(is.na(lookup)))
  expect_false(any(lookup == ""))
  expect_false(any(duplicated(lookup$genus)))
  expect_is(plant_lookup_version_current_local(),"character")
  expect_is(plant_lookup_version_current_github(),"character")
  only_corn<-subset(lookup,lookup$genus=="Zea")
  expect_true(only_corn$family[1]=="Poaceae")
  expect_true(only_corn$order[1]=="Poales")
  expect_true(only_corn$group[1]=="Angiosperms")

  #test additions
  only_tassy<-subset(lookup,lookup$genus=="Tetracarpaea")
  expect_true(only_tassy$family[1]=="Tetracarpaeaceae")
})
