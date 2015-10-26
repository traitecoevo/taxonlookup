# taxonlookup: a taxonomic lookup table for land plants

[![Build Status](https://travis-ci.org/traitecoevo/taxonlookup.png?branch=master)](https://travis-ci.org/traitecoevo/taxonlookup)
[![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.32636.svg)](http://dx.doi.org/10.5281/zenodo.32636)

This is designed to be a living database--it will update as taxonomy changes (which it always will). These updates will correspond with changes to the version number of this resource, and each version of the database will be available via [travis-ci](http://travis-ci.org) and [Github Releases](http://docs.travis-ci.com/user/deployment/releases/). If you use this resource for published analysis, please note the version number in your publication.  This will allow anyone in the future to go back and find **exactly** the same version of the data that you used.
 
The core of this repository is a set of scripts that dynamically build a genus-family-order-higher taxa look-up table for land plants with the data lookup primarily coming from three sources (with most of the web-scraping done by [taxize](https://github.com/ropensci/taxize)): 

1. [The Plant List](http://www.theplantlist.org/) for accepted genera to families

2. [APWeb](http://www.mobot.org/MOBOT/research/APweb/) for family-level synonymies and family to order as curated by [Peter Stevens](http://www.umsl.edu/~biology/About%20the%20Department/Faculty/stevens.html)

3. [A higher-level taxonomy lookup](http://datadryad.org/resource/doi:10.5061/dryad.63q27.2/1.1) compiled by [Dave Tank](http://phylodiversity.net/dtank/Tank_Lab/Tank_Lab.html) and colleagues

We have a complete genus-family-order mapping for vascular plants. For bryophytes, there is only genus-family mapping at present; if anyone has a family-order map for bryophytes, please let me know. We also correct some spelling errors, special character issues, and other errors from The Plant List.  We will try to keep this curation up-to-date, but there may new errors introduced as the cannonical data sources shift to future versions.  

The scripts are in the repository but not in the package.  Only the data and ways to access the data are in the package; the reason for this design will become clear further down the readme.  To use the data from the most recent release first install and load `devtools`; that will then let you load the one dependancy and then the `taxonlookup` package from this respository:

```r
install.packages("devtools")
devtools::install_github("hadley/httr")
devtools::install_github("richfitz/storr")
devtools::install_github("wcornwell/taxonlookup")
library(taxonlookup)
```

Then you can download and load the data into `R` using the `plant_lookup()` function:

```r
head(plant_lookup())
```

The first call to `plant_lookup` will download the data, but subsequent calls will be essentially instantaneous.  If you are interested in diversity data, the data object also stores the number of accepted species within each genus as per the plant list:

```r
head(plant_lookup(include_counts = TRUE))
```

For taxonomic groups higher than order, use the `add_higher_order()` function.  Because currently the higher taxonomy of plants does not have a nested structure, the format of that lookup table is a little more complicated.  Check the help file for more details.  To get the version number of the dataset run:

```r
plant_lookup_version_current()
```

For most uses, the latest release should be sufficient, and this is all that is necessary to use the data.  
However, if there have been some recent changes to taxonomy  that are both important for your project and incorporated in the cannical sources (the plant list or APWeb) but are more recent than the last release of this package, you might want to rebuild the lookup table from the sources. Because this requires downloading the data from the web sources, this will run  slowly, depending on your internet connection.  

# Rebuilding the lookup table

To build the lookup table, first clone this repository.  Then install the required packages from CRAN:

```r
	install.packages(c("R6","yaml","digest","devtools"))
```

Download and install 3 additional packages from github:    

```r
	devtools::install_github("richfitz/storr")
	devtools::install_github("richfitz/remake")
	devtools::install_github("ropensci/taxize")
```

This will require a recent version of taxize, so if you have that already installed an older version, please re-install.  Then run the following command from within R.  Make sure the home directory is within the repository:

```r
	remake::make()
```	

This requires a working internet connection and that the plant list, mobot, and datadryad servers are up and working properly.  This will dynamically re-create the lookup tables within your local version of the package, as well as save the main file as a `.csv` in your home directory.

# Living database

## Stable version

Eventually this package will exist on CRAN; versions there will be our "stable releases" and will generally correspond to an increase in the first version number.

## Development version

We will periodically release development versions of the database using github releases (every CRAN release will also be a github release).  We'll do this automatically using [travis-ci](http://travis-ci.org) using its [deploy to github releases](http://docs.travis-ci.com/user/deployment/releases/) and [conditional deployment](http://docs.travis-ci.com/user/deployment/#Conditional-Releases-with-on%3A) features.  This will correspond to an increase in the second version number and also to the first version number when simultaneously being released to CRAN.

## Bleeding edge version

Download the package and rerun the build script.  We'll work this way as we add new data to the package.

# Notes for making a release using this *living dataset* design

* Update the `DESCRIPTION` file to increase the version number.  Once we hit version 1, we use [semantic versioning](http://semver.org/) so be aware of when to change what number.  Assume it's `1.2.3` for the rest of instructions.
* Run `remake::make()` to rebuild `plant_lookup.csv`
* Commit and push to github
* In github, create a new release [link](https://github.com/wcornwell/taxonlookup/releases/new)
  - Tag version must be prefixed with the letter "v", e.g., `v1.2.3`
  - In the release title / description give a short descripton about what the feature(s) that this release adds is/are
  - Drag the `plant_lookup.csv` file into the upload area or use the "selecting them" link
  - Click "Publish release"
* Check that it works by running `taxonlookup::plant_lookup("1.2.3")` which should pull the data.
