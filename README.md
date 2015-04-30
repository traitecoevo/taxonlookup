# TaxonLookup: a set of scripts to dynamically build a genus-family-order lookup for vascular plants

[![Build Status](https://travis-ci.org/wcornwell/TaxonLookup.png?branch=master)](https://travis-ci.org/wcornwell/TaxonLookup)


This is a set of scripts that dynamically build a genus-family-order look-up table for vascular plants.  As long as the canonical sources of the data stay in the same format, this should build an up-to-date lookup table. The data primarily comes from two sources: 

1. [The Plant List](http://www.theplantlist.org/) for accepted genera to families

2. [APWeb](http://www.mobot.org/MOBOT/research/APweb/) for family level synonymies and family to order

To complete the family to order data (beyond the taxonomic scope of APWeb) we add a few additional family to order mappings for ferns.  We also correct some spelling errors and special character issues from The Plant List.  We will try to keep this up-to-date, but there may new errors introduced as the cannonical data sources shift to future versions.  

To build the lookup table, first install the required packages from CRAN:

	install.packages(c("R6","yaml","digest","devtools"))

Download and install 3 additional packages from github:    

	devtools::install_github("richfitz/storr")
	devtools::install_github("richfitz/remake")
	devtools::install_github("ropensci/taxize")

Then run the following command from within R.  Make sure the home directory is within the repository:

	remake::make()
	
This requires a working internet connection and that both the plant list and mobot servers are up.  The should create a new lookup table called `genusFamilyOrder.csv` within your repository.  
