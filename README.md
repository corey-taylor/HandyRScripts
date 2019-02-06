# HandyRScripts

This repo is primarily to store handy quick R scripts for post-processing and such.

## Shell scripts

### ProcessMol2.sh

Processing SEED output prior to feeding into R scripts RDataImport.R and RDataImportDSX.R.

## R scripts

### RDataImport.R

Takes in list of poses and scores (usually 000's) from SEED output, applies data transform (^2) to make data normally distributed, retains poses scoring two-sigma away from the mean, outputs list of these poses.

### RDataImportDSX.R

Takes poses after rescoring by DSX (http://pc1664.pharmazie.uni-marburg.de/drugscore/), retains poses scoring two-sigma from mean from docking AND DSX rescoring.
