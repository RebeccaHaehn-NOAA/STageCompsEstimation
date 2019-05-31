rm(list = ls())

# Required libraries:
require(sp)
library(gstat)
require(BBmisc)
require(ggplot2)
require(ALKr)
require(reshape2)
library(mgcv)
library(mapdata)
library(grid)
library(RColorBrewer)
require(geoR)

# call aux functions needed for the simulation:
source('auxFunctionsSimulation.R')

# parameters for the simulation and estimation step:
source('parametersSimulation.R')

# main code for simulation (population and sampling):
source('mainSimulation3.R') # simulation1 is length stratified. simulation2 is random sampling

# check results from simulation: some figures will be created:
source('checkSimulation.R')

# estimates from the sampling output (e.g. total abundance, len abundance):
source('estimatesSimulation.R')

# Final Step (?): compare age props between different methods
source('compareMethods.R')