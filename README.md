# TaxonLookup: a set of scripts to dynamically build a genus-family-order lookup for vascular plants

[![Build Status](https://travis-ci.org/wcornwell/TaxonLookup.png?branch=master)](https://travis-ci.org/wcornwell/TaxonLookup)

The data for this lookup primarily comes from two sources: 

1. [The Plant List](http://www.theplantlist.org/) for accepted genera to families

2. [APWeb](http://www.mobot.org/MOBOT/research/APweb/) for family level synonymies and family to order

To complete the family to order data (beyond the taxonomic scope of APWeb) we add a few additional family to order mappings for non-seed plants (mostly ferns).  We also correct some spelling errors, special character issues, and other errors from The Plant List.  We will try to keep this up-to-date, but there may new errors introduced as the cannonical data sources shift to future versions.  

To use the data from the most recent release.  First install and load devtools; that will then let you load the package from this respository:

```{r}
install.packages(c("devtools"))
library(devtools)
install_github("wcornwell/TaxonLookup")
library(TaxonLookup)
```

Then you can load the data:

`data(plant_lookup)`

And the look up table will then be in R's memory.  

`head(plant_lookup)`

If there have been some recent changes to taxonomy you might want to rebuilding the lookup table.  See the section below.

# Rebuilding the lookup table

This is a set of scripts that dynamically build a genus-family-order look-up table for vascular plants.  As long as the canonical sources of the data stay in the same format, this should build an up-to-date lookup table. 

To build the lookup table, first clone this repository.  Then install the required packages from CRAN:

	install.packages(c("R6","yaml","digest","devtools"))

Download and install 3 additional packages from github:    

	devtools::install_github("richfitz/storr")
	devtools::install_github("richfitz/remake")
	devtools::install_github("ropensci/taxize")

Or, if you already have remake installed run

    remake::install_missing_packages()

Then run the following command from within R.  Make sure the home directory is within the repository:

	remake::make()
	
This requires a working internet connection and that both the plant list and mobot servers are up.  This will create a new lookup table in the package.

# Living database

## Stable version

Eventually this package will exist on CRAN; versions there will be our "stable releases" and will generally correspond to an increase in the first version number.

## Development version

We will periodically release development versions of the database using github releases (every CRAN release will also be a github release).  We'll do this automatically using [http://travis-ci.org](travis-ci) using its [deploy to github releases](http://docs.travis-ci.com/user/deployment/releases/) and [conditional deployment](http://docs.travis-ci.com/user/deployment/#Conditional-Releases-with-on%3A) features.  This will correspond to an increase in the second version number and also to the first version number when simultaneously being released to CRAN.

## Bleeding edge version

Download the package and rerun the build script.  We'll work this way as we add new data to the package.
