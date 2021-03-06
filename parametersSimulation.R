
# New Parameters:

setwd('C:/Users/moroncog/Documents/GitHub/STageCompsEstimation')

	# define if simulation is run. if simulation is FALSE, all plots will be created.
	simulation = TRUE
	# Scenario name:
	scenario1 = 'NoS'
	scenario2 = 'NoT'
	scenarioName = paste0(scenario1, '_', scenario2)

# Scenarios definitions:
# 'HighS'
# 'NoS'
# 'HighT'
# 'NoT'


# Read some data:
#SelecSurvLen = read.csv('SurveySelecLen.csv') # read survey length selectivity
sampleStations = read.csv('sampledGrids.csv') # read sample stations. WARNING!!!! THIS SHOULD CHANGE IF THE GRID SIZE CHANGE!!!!!!

# Grid size:
dsGrid = 6 # in nautical miles # maybe the best value is 1.5, but for time reasons do it = 6

# Create the grid:

xgrid = seq(from = -179, to = -158, by = dsGrid/60)
ygrid = seq(from = 54, to = 62, by = dsGrid/60)
predictGrid = expand.grid(xgrid,ygrid)
names(predictGrid) = c("x","y")

surveyPolygon = read.csv('polygonSurvey.csv') # this is the survey standard area
predictGrid2 = predictGrid[which(point.in.polygon(point.x = predictGrid$x, point.y = predictGrid$y, 
                                                  pol.x = surveyPolygon$x, pol.y = surveyPolygon$y) == 1), ]
# 9376 rows for 6 mn grid. so, total area = 9376 * 36 = 337536 mn2 = 1159196.5 km2
# 36 nm2 = 123.6 km2. Factor = 3.43

# Rec density:
iniR0 = 451155e03 # This is a unique value for the first year. Average of R0 1994-2016 from SS3 results.
StudyArea = nrow(predictGrid2)*dsGrid*dsGrid*3.43 # in km2 = 1157748 
GridArea = dsGrid*dsGrid*3.43

# R0inidengrid = R0inidenkm2*dsGrid*dsGrid*3.43 # abundance per grid.

# These parameters will be used later:
iniYear = 1985
iniYearSam = 1994
endYear = 2016
maxAge = 20
minAge = 0
minEstAge = 1
maxLen = 120
minLen = 1
lenBin = 1
dT = 1
wS = 0.03
wT = 0.03
SpatialScale = 0.5 # st value = 0.5
SD_O = 0.5 # st value = 0.5
SD_E = 0.4 # st value = 0.2
NuMat = 1 # st value = 1
#thPr = 1e-03
maxNSamAge = 4 # number of ind sampled in station j for age (random sampling)
#maxNSamPerAge = 120 # max number of ind sampled for age in length bin l in the survey. THIS SHOULD NOT BE A RESTRICTION ? (random sampling)
#maxNSamAgeStation = 3 # max number of ind of length bin l sampled in station j for age (random sampling)
t1 = 0.3 # first dt for natural and fishing mortality
Linf = 118.6 # L2 in SS
K_par = 0.1376 # 0.195 is the value in SS. seems to be very high.
M_par = 0.34

# I consider that the best way to control the spatiotemporal variability in growth and spawning time on size-at-age CV is 
# to fix these number and just vary saptial and temporal components of the K parameter. 
CV1 = 3.45 # this is a sd. 3.45 is the value in SS. 0.8, 2.41, 3.45, 4.485
CV2 = 9.586 # this is a sd. 9.586 is the value in SS. 3, 6.7, 9.586, 9.586
typeCV = expression('high-'*sigma[a])

L1_par = 10 # same as SS. L1
A1_par = 0.5 # same as SS. a3
A2_par = 18.5 # a4 in SS
t0 = -0.168
F_par = 0.46 # SS results. Apical F
areaSwept = 0.05 # km2. average of all data: 1994 - 2016. a
nSamLoc = round(nrow(sampleStations)*0.95) # number of age sample locations. 95% all locations = 332 so far
sigmaR = 0.66# for recruitment
sigmaM = 0.7 # for simulated catches
lenCatchTh = 200 #th in length sample
SelecFish = c(0, 0.000231637, 0.00279779, 0.0328583, 0.29149, 0.832831, 0.983694, 0.998633, 0.999887, 
             1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1) # FISHERY. from age 0 to 20. be sure it has same length as allAges
SelecSurv = c(0, 1, 1, 1, 1, 1, 1, 1, 1, 
              1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)# SURVEY. from age 0 to 20. be sure it has same length as allAges

YearALKPlot = 2004
agePlus = 8

# Derived quantities:
allAges = seq(from = minAge, to = maxAge, by = dT)
allYears = seq(from = iniYear, to = endYear, by = dT)
allYearsSam = seq(from = iniYearSam, to = endYear, by = dT)
allLens = seq(from = minLen, to = maxLen, by = lenBin)

PhiPopulation = matrix(0, ncol = length(allAges), nrow = length(allLens))
AbunLenAgePopulation = matrix(0, ncol = length(allAges), nrow = length(allLens))
AbunLenAgePopulation2 = matrix(0, ncol = length(minEstAge:agePlus), nrow = length(allLens))
AbunLAGrid = AbunLenAgePopulation2

indYearALK = which(allYears == YearALKPlot)

# --------------------------------------------------------------
# Parameters for the estimation part


# some colors
gradColors = rev(brewer.pal(n = 9, name = "Spectral"))
gradColors2 = alpha(gradColors, alpha = 0.3)


# --------------------------------------------------------------
# Random Fields for growth parameters 

# Spatial:
	gDummy2 = gstat(formula=z~1+x+y, locations=~x+y, dummy=T, beta=c(0,0.15,0.5), 
					 model=vgm(psill=0.05, range=5, model='Mat'), nmax = 15)
	yy2 = predict(gDummy2, newdata=predictGrid2, nsim=1)
	gridded(yy2) = ~x+y
	yy2$sim1 = normalize(x = yy2$sim1, method = 'range', range = c(wS,-1*wS)) # this value (0.05) give us a difference of 5 cm between strata.

if(scenario1 == 'NoS'){
	yy2$sim1 = rep(x = 0, times = nrow(predictGrid2))
}
  
# Temporal trend in K parameter:
	KparT = normalize(x = allYears, method = 'range', range = c(-1*wT,wT))


if(scenario2 == 'NoT'){
	KparT = rep(x = 0, times = length(allYears))
}


# --------------------------------------------------------------
# Plot of random field spatial:

if(ix == 1){

ak = map_data('worldHires','USA:Alaska')
ak = ak[ak$long < 0, ]

bitmap(paste0('RandomField_K_', scenarioName, '.tiff'), height = 65, width = 130, units = 'mm', res = 900)
print(map.heatmap(lat = yy2@coords[,2], lon = yy2@coords[,1], yy2@data,
              color_low = "blue", color_high = "red", zeroiswhite = TRUE, xlim = c(-179,-158), ylim = c(54,62.5)) +
			  geom_polygon(data = ak, aes(long, lat, group = group), 
			  fill = 8, color="black") +
			  xlab('longitude') +
			  ylab('latitude') +
			  #xlim(-180,-156) +
			  theme(legend.position = c(0.15, 0.15), plot.margin = unit(c(0,0,0,0),"cm"), legend.key.width = unit(0.5, "cm")))
dev.off()  

}