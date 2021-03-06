
#L'min in SS equations:
Lminp = minLen - lenBin*0.5 # 0.5 because I am working with cm
bpar = (L1_par-Lminp)/A1_par

Z_par = M_par + (F_par*SelecFish)
#ageStrucAll = matrix(NA, nrow = length(allYears), ncol = length(allAges))#matrix to save the TOTAL age structure at the end of the first half.
NageStrucGrid = array(NA, dim = c(nrow(predictGrid2), length(allAges), length(allYears)))#matrix to save the age structure at the end of the sampling (t1 time)
LageStrucGrid = array(NA, dim = c(nrow(predictGrid2), length(allAges), length(allYears)))#matrix to save the length at age values at the end of the sampling (t1 time)
NageStrucGridSam = array(NA, dim = c(nrow(predictGrid2), length(allAges), length(allYears)))#matrix to save the age structure at the end of the sampling (t1 time)
LageStrucGridSam = array(NA, dim = c(nrow(predictGrid2), length(allAges), length(allYears)))#matrix to save the length at age values at the end of the sampling (t1 time)


#currentDate = format(Sys.time(), "%b %d %Y %X")
#currentDate = gsub(pattern = ' ', replacement = '_', x = currentDate)
#currentDate = gsub(pattern = ':', replacement = '', x = currentDate)

# Simulation --------------------------------------------------------------
allcatchData = NULL # to save catch data
alllenData = NULL # to save len data
allageData = NULL # to save age data
for(k in seq_along(allYears)){

	# Rec for this year:
	R0year = iniR0*exp(rRecTemp[k])
	
	# Rec in density terms
	R0inidengrid = log(R0year/StudyArea) # Nfish/km2: mean density in log scale

	# define age sample locations. ALL RANDOM.
	ageLocations =  sample(x = sampleStations$sampledGrids, size = nSamLoc, replace = FALSE)

	# length counting in samples: max should be 25
	# tmpLenCount = 0

	# create vector of sample for age
	# nFishAgeSampled = numeric(length(allLens))

  for(j in seq_along(yy2@grid.index)){

	if(k == 1){
		# Initial conditions:    
		R0grid = exp(R0inidengrid + Omega1[j] + Epsilon1[j,k]) # add spatial and spatiotemporal structure
		iniNs   = R0grid*exp(-Z_par*allAges) # take care: Z mortality
		#iniLens = ifelse(allAges <= A1_par, Lminp + (bpar*allAges), Linf+(L1_par-Linf)*exp(-(K_par+KparT[k]+yy2$sim1[j])*(allAges-A1_par))) # SS growth, Age vs Len relationship
		iniLens = Linf*(1-exp(-(K_par+KparT[k]+yy2$sim1[j])*(allAges-t0))) # VB growth
		lenatage0 = iniLens[1]
	} else {
		iniNs = toNewYear(vec = NageStrucGrid[j,,(k-1)], firstVal = exp(R0inidengrid + Omega1[j] + Epsilon1[j,k])) # define what is R0x
		iniLens = toNewYear(vec = LageStrucGrid[j,,(k-1)], firstVal = lenatage0)
	}

    # Save state of the population at time t
    nTmp = iniNs
    lTmp = iniLens
    
    # First half: Natural mortality: time step t1*dT
    nTmp2	= nTmp*exp(-dT*t1*Z_par)
    # Individual growth: time step t1*dT
    lTmp2 = lTmp + (lTmp-Linf)*(exp(-dT*t1*(K_par+KparT[k]+yy2$sim1[j])) - 1)
    
    # SD len after first half: 
    sdTmp2 = numeric(length(lTmp2))
    # for(l in seq_along(sdTmp2)){
      
      # if(allAges[l] <= A1_par) sdTmp2[l] = CV1
      # if(allAges[l] > A1_par & allAges[l] < A2_par) sdTmp2[l] = (CV1 + ((lTmp2[l] - lTmp[2])/(lTmp[(maxAge - 1)] - lTmp[2]))*(CV2-CV1))
      # if(allAges[l] >= A2_par) sdTmp2[l] = CV2
      
    # }
    
#	sdTmp2 = ifelse(allAges <= A1_par, CV1, (CV1 + ((lTmp2 - L1_par)/(Linf - L1_par))*(CV2-CV1))) # SS growth, Age vs Len relationship
#	sdTmp2 = ifelse(allAges >= A2_par, CV2, sdTmp2) # SS growth, Age vs Len relationship

	sdTmp2 = CV1 + ((lTmp2 - L1_par)/(Linf - L1_par))*(CV2-CV1) # SS growth, Age vs Len relationship


		nTmp3 = nTmp2
		lTmp3 = lTmp2
#    	sdTmp3 = sdTmp2

    
    # Create Age Length matrix after first half: (just for sampled grids)
	
	if(j %in% sampleStations$sampledGrids & allYears[k] %in% allYearsSam){
		
		AgeLenMatrixProp = matrix(NA, ncol = length(allAges), nrow = length(allLens))
		
		for(i in 1:nrow(AgeLenMatrixProp)){
		
		  if(i == 1){
		  
			#Lminp = minLen - lenBin*0.5 # 0.5 because I am working with 1 cm bin
			Fac1 = (Lminp - lTmp2)/sdTmp2
			AgeLenMatrixProp[i, ] = pnorm(Fac1)
		  
		  }
		  if(i == length(allLens)){
			
			Lmaxp = maxLen - lenBin*0.5
			Fac1 = (Lmaxp - lTmp2)/sdTmp2
			AgeLenMatrixProp[i, ] = 1 - pnorm(Fac1)
		
		  } else {
			
			Ll1p = allLens[i] + lenBin*0.5
			Llp = allLens[i] - lenBin*0.5
			Fac1 = (Ll1p - lTmp2)/sdTmp2
			Fac2 = (Llp - lTmp2)/sdTmp2
			AgeLenMatrixProp[i, ] = pnorm(Fac1) - pnorm(Fac2)
			
		  }
			
		}
		
		AgeLenMatrix = sweep(AgeLenMatrixProp, MARGIN=2, nTmp2, `*`)

		if(k == indYearALK & ix == 1) {
			PhiPopulation = PhiPopulation + AgeLenMatrixProp
			AbunLenAgePopulation = AbunLenAgePopulation + AgeLenMatrix
		}

		# SAVE INFO FOR ONE GRID:

		if(j == sampleStations$sampledGrids[1] & k == indYearALK & ix == 1){

				AbunLAGrid[,1] = AgeLenMatrix[, c(2)]
				AbunLAGrid[,2:7] = AgeLenMatrix[, 3:8]
				AbunLAGrid[,8] = rowSums(AgeLenMatrix[, 9:ncol(AgeLenMatrix)])

				ALKpopGrid = calc_ALK(x = AbunLAGrid)

				write.csv(ALKpopGrid, paste0('ALKPopulationGrid', scenarioName, '_CV1_', CV1, '_CV2_', CV2, '.csv'))

		}


		
# Here: sampling strategy:
# --------------------
		# follow Thorson and Haltuch 2019 method: delta model (see equation 16). and Thorson (2018): select length and age at the same time
		SelAbun = sweep(AgeLenMatrix, MARGIN=2, SelecSurv, `*`)
		SelAbun2 = rowSums(SelAbun)
		pL = 1 - exp(-areaSwept*SelAbun)
		pLsim = structure(vapply(pL, rbinom, numeric(1), n = 1, size = 1), dim=dim(pL))
		rL = (areaSwept*SelAbun)/pL # as poisson delta link model. add over pL if it is necessary.
		findNAN = which(is.nan(rL)|is.infinite(rL))
		rL[findNAN] = 1 # to avoid warnings
		#rLsim = structure(vapply(log(rL)-(sigmaM^2)/2, rlnorm, numeric(1), n = 1, sdlog = sigmaM), dim=dim(rL)) # lognormal
		randomNumbers = structure(rnorm(nrow(rL)*ncol(rL), mean = 0, sd = sigmaM), dim=dim(rL))
		rLsim = structure(vapply(rL*exp(randomNumbers), rpois, numeric(1), n = 1), dim=dim(rL)) # poisson
		roundAgeLenSampled = pLsim*rLsim # get round sampled matrix
		nFishLenSampled = rowSums(roundAgeLenSampled) # here the 1s are deleted.
		catchStation = sum(nFishLenSampled)
# --------------------

		# check sampling: (catch data)
		# nFishSampled = sum(roundAgeLenSampled)
		nFishSampled = catchStation
		catchData = data.frame(YEAR = allYears[k], STATIONID = j, START_LONGITUDE = sampleStations$lon[sampleStations$sampledGrids == j], 
							   START_LATITUDE = sampleStations$lat[sampleStations$sampledGrids == j], 
								STRATUM_ALT = sampleStations$stratum[sampleStations$sampledGrids == j],
								STRATUM = sampleStations$stratum2[sampleStations$sampledGrids == j],
								STRATUM3 = sampleStations$stratum3[sampleStations$sampledGrids == j],
								TYPEGRID = sampleStations$typegrid[sampleStations$sampledGrids == j],
								NUMBER_FISH = nFishSampled)
		allcatchData = rbind(allcatchData, catchData)

		# check sampling: (len data): apply function. max th
		
		if(nFishSampled > 0){ # just for positive catches
			# For catch sample less than th:
			if(nFishSampled <= lenCatchTh){
				nFishLenSampled2 = nFishLenSampled
				posLenSam = which(nFishLenSampled2 > 0)
				lenData = data.frame(YEAR = allYears[k], STATIONID = j, LON = sampleStations$lon[sampleStations$sampledGrids == j], 
									   LAT = sampleStations$lat[sampleStations$sampledGrids == j], 
										STRATUM_ALT = sampleStations$stratum[sampleStations$sampledGrids == j],
										STRATUM = sampleStations$stratum2[sampleStations$sampledGrids == j],
										STRATUM3 = sampleStations$stratum3[sampleStations$sampledGrids == j],
										TYPEGRID = sampleStations$typegrid[sampleStations$sampledGrids == j],
										LENGTH = allLens[posLenSam], FREQUENCY = nFishLenSampled2[posLenSam])
				alllenData = rbind(alllenData, lenData)
			}
			# For catch sample greater than th:
			if(nFishSampled > lenCatchTh){
				nFishLenSampled3 = sample(x = rep(allLens, times = nFishLenSampled), size = lenCatchTh, replace = FALSE)
				prev2 = table(nFishLenSampled3)
				nFishLenSampled2 = numeric(length(allLens))
				nFishLenSampled2[allLens %in% as.numeric(names(prev2))] = as.vector(prev2)
			
				posLenSam = which(nFishLenSampled2 > 0)
				lenData = data.frame(YEAR = allYears[k], STATIONID = j, LON = sampleStations$lon[sampleStations$sampledGrids == j], 
									   LAT = sampleStations$lat[sampleStations$sampledGrids == j], 
										STRATUM_ALT = sampleStations$stratum[sampleStations$sampledGrids == j],
										STRATUM = sampleStations$stratum2[sampleStations$sampledGrids == j],
										STRATUM3 = sampleStations$stratum3[sampleStations$sampledGrids == j],
										TYPEGRID = sampleStations$typegrid[sampleStations$sampledGrids == j],
										LENGTH = allLens[posLenSam], FREQUENCY = nFishLenSampled2[posLenSam])
				alllenData = rbind(alllenData, lenData)
			}
			
		}

		# check sampling: (age data): simple strategy: max 25 ind per length IN THE SURVEY. max 50 ind sampled in a station. max 3 ind per length in A STATION.
		
		# ALL AREA ALL STATIONS: RANDOM SAMPLING. 
		if(j %in% ageLocations & nFishSampled > 0){ # no run this part if the n fish sampled for length  = 0
		
			# choose length to be age sampled:
			if(maxNSamAge > sum(nFishLenSampled2)){
				lFishSampled = rep(allLens, times = nFishLenSampled2) # max ind per set for age sample = 40. FIRST CONDITIONAL				
			} else {
				lFishSampled = sample(x = rep(allLens, times = nFishLenSampled2), size = maxNSamAge, replace = FALSE) # max ind per set for age sample = 40. FIRST CONDITIONAL
			}
			
			prev = table(lFishSampled)
			nFishToAge = numeric(length(allLens))
			nFishToAge[allLens %in% as.numeric(names(prev))] = as.vector(prev)
			
					# now, choose age at length to be sampled:
					if(max(nFishToAge) > 0){ # just if there are more lengths to be aged
						agesSam = ageSample(mat = roundAgeLenSampled, vec = nFishToAge)
						lensSam = rep(as.numeric(names(prev)), times = as.numeric(prev)) # length in order

						ageData = data.frame(YEAR = allYears[k], STATIONID = j, LON = sampleStations$lon[sampleStations$sampledGrids == j], 
									   LAT = sampleStations$lat[sampleStations$sampledGrids == j], 
										STRATUM_ALT = sampleStations$stratum[sampleStations$sampledGrids == j],
										STRATUM = sampleStations$stratum2[sampleStations$sampledGrids == j],
										STRATUM3 = sampleStations$stratum3[sampleStations$sampledGrids == j],
										TYPEGRID = sampleStations$typegrid[sampleStations$sampledGrids == j],
										LENGTH = lensSam, AGE = agesSam)
						allageData = rbind(allageData, ageData)
					}

		}
    
		nTmp3 = nTmp2
		lTmp3 = lTmp2

	}
    
	# save the age structure per grid
	#ageStrucMidYear = ageStrucMidYear + nTmp3 # sum the age structure at each grid. at the end of the grid loop I will have the total population structure
	
    # After the survey sample simulation: run the second half of dT:
    nTmp4 = nTmp3*exp(-dT*(1-t1)*Z_par)
    lTmp4 = lTmp3 + (lTmp3-Linf)*(exp(-dT*(1-t1)*(K_par+KparT[k]+yy2$sim1[j])) - 1) # Individual growth: time step 0.5*dT
    
	NageStrucGrid[j,,k] = nTmp4
	LageStrucGrid[j,,k] = lTmp4
	
	NageStrucGridSam[j,,k] = nTmp3
	LageStrucGridSam[j,,k] = lTmp3
	    
  }
  
  #ageStrucAll[k, ] = ageStrucMidYear
  # print(k)
}

dir.create('simData', showWarnings = FALSE)

if(ix == 1){
	write.csv(allcatchData, paste0('simData/paccod_catch_Sim_', scenarioName, '.csv'), row.names = FALSE)
	write.csv(alllenData, paste0('simData/paccod_len_Sim_', scenarioName, '.csv'), row.names = FALSE)
	write.csv(allageData, paste0('simData/paccod_age_Sim_', scenarioName, '.csv'), row.names = FALSE)
}

# needed for compareMethods.R:
NAgeYearMatrix = t(apply(X = NageStrucGridSam, MARGIN = c(2,3), FUN = sum)*GridArea)
if(ix == 1){
	write.csv(NAgeYearMatrix, paste0('simData/NAgeYearMat_', scenarioName, '.csv'), row.names = FALSE)
}

#save(NageStrucGridSam, file = 'simData/simAgeStructure.RData')
#save(LageStrucGridSam, file = 'simData/simLengthAtAge.RData')

# Plot survey map (for the last year = 2016):

timeSurvey = data.frame(lon = yy2@coords[,1], lat = yy2@coords[,2], time = 1:nrow(yy2@coords))
lenStations = data.frame(lon = yy2@coords[sampleStations$sampledGrids, 1], lat = yy2@coords[sampleStations$sampledGrids, 2])
ageStations = data.frame(lon = yy2@coords[ageLocations, 1], lat = yy2@coords[ageLocations, 2])
#ageStations2 = data.frame(lon = yy2@coords[ageLocations2, 1], lat = yy2@coords[ageLocations2, 2])

# png('surveyDescription.png', height = 700, width = 700, units = 'px', res = 110)
# print(ggplot(timeSurvey, aes(lon, lat)) +
        # geom_point(aes(color = time), size = 1.5) +
		# geom_point(data = lenStations, aes(lon, lat), col = 1) +
		# geom_point(data = ageStations1, aes(lon, lat), col = 4, shape = 2) +
		# geom_point(data = ageStations2, aes(lon, lat), col = 5, shape = 2) +
        # scale_colour_gradientn(colours = gradColors2) +
		# theme_bw())
# dev.off()

if(ix == 1){

	ax1 = map.heatmap(lat = yy2@coords[,2], lon = yy2@coords[,1], yy2@data,
              color_low = "blue", color_high = "red", zeroiswhite = TRUE, xlim = c(-179,-158), ylim = c(53.5,63)) +
			  geom_polygon(data = ak, aes(long, lat, group = group), 
			  fill = 8, color="black") +
			  xlab('longitude') +
			  ylab('latitude') +
			  #xlim(-180,-156) +
			  theme(legend.position = 'none') +
			  theme(plot.margin = unit(c(0,0,0,0),"cm"))
	
	
	ax2 = ggplot(lenStations, aes(lon, lat)) +
			geom_point(size = 0.9) +
			#geom_point(data = ageStations, aes(lon, lat), col = 'red', shape = 2) +
			#geom_point(data = ageStations2, aes(lon, lat), col = 'blue', shape = 2) +
			geom_polygon(data = ak, aes(long, lat, group = group), 
				  fill = 8, color="black") +
			theme_bw() +
			xlab(' ') +
			ylab('latitude') +
			coord_fixed(ratio=1, xlim=c(-179,-158), ylim=c(53.5,63)) +
			theme(plot.margin = unit(c(0,0,0,0),"cm"))


	bitmap(paste0('surveyDescription3R_', scenarioName, '.tiff'), height = 110, width = 90, units = 'mm', res = 500)
	
	grid.arrange(ax2, ax1, nrow = 2)
			
	dev.off()  
}


if(ix == 1){

	ax3 = map.heatmap2(lat = yy2@coords[,2], lon = yy2@coords[,1], data = yy2@data, data2 = lenStations,
              color_low = "blue", color_high = "red", zeroiswhite = TRUE, xlim = c(-179,-158), ylim = c(53.5,63), pSize = 0.65) +
			  geom_polygon(data = ak, aes(long, lat, group = group), 
			  fill = 8, color="black") +
			  xlab('longitude') +
			  ylab('latitude') +
			  theme(legend.position = c(0.5, 1.18), plot.margin = unit(c(0,0,0,0),"cm"), legend.key.width = unit(0.75, "cm"), 
			  	legend.text=element_text(size=7.5))

	bitmap(paste0('surveyDescription4R_', scenarioName, '.tiff'), height = 55, width = 90, units = 'mm', res = 500)
	
	print(ax3)
			
	dev.off()  
}

if(ix == 1){

	PhiPopulation = PhiPopulation/length(sampleStations$sampledGrids)

	png(paste0('PhiPopulation_', scenarioName, '_CV1_', CV1, '_CV2_', CV2, '.png'), height = 550, width = 700, units = 'px', res = 130)

		par(mar = c(4,4,0.5, 1))
		image.plot(t(PhiPopulation), axes = FALSE, xlab = 'Ages', ylab = 'Length (cm)', legend.lab = 'Proportion', legend.line = 2.8)
		axis(2, at = seq(0, 1, length.out = 5), labels = floor(seq(minLen, maxLen, length.out = 5)), las = 2)
		axis(1, at = seq(0, 1, length.out = maxAge+1), labels = seq(minAge, maxAge, by = 1))

	dev.off()

	png(paste0('AbunAgeLenPopulation_', scenarioName, '_CV1_', CV1, '_CV2_', CV2, '.png'), height = 550, width = 700, units = 'px', res = 130)

		par(mar = c(4,4,0.5, 1))
		image.plot(t(AbunLenAgePopulation[,-c(1,10:21)]), axes = FALSE, xlab = 'Ages', ylab = 'Length (cm)', legend.lab = 'Abundance', legend.line = 2.8)
		axis(2, at = seq(0, 1, length.out = 5), labels = floor(seq(minLen, maxLen, length.out = 5)), las = 2)
		axis(1, at = seq(0, 1, length.out = agePlus), labels = seq(minEstAge, agePlus, by = 1))

	dev.off()


	rownames(AbunLenAgePopulation) = allLens
	colnames(AbunLenAgePopulation) = allAges
	AbunLenAgePopulation3 = AbunLenAgePopulation[,1:9]
	newAbunLen = melt(AbunLenAgePopulation3)
	names(newAbunLen) = c('Length', 'Age', 'Abundance')

	png(paste0('AbunAgeLenPopulation_Mat_', scenarioName, '_CV1_', CV1, '_CV2_', CV2, '.png'), height = 550, width = 700, units = 'px', res = 135)

		ggplot(newAbunLen, aes(x=Length,y=Abundance,group=factor(Age),colour=factor(Age))) +
			geom_line(linetype = "solid") +
			xlab(label = 'Length (cm)') +
	    	ylab(label = 'Abundance') +
			theme_bw() +
			labs(colour = "Age") +
			xlim(0, 115) +
			theme(legend.position = c(0.8, 0.6)) +
			ggtitle(typeCV)

	dev.off()

	#AbunLenAgePopulation2[,1] = rowSums(AbunLenAgePopulation[, c(1,2)])
	AbunLenAgePopulation2[,1] = AbunLenAgePopulation[, c(2)]
	AbunLenAgePopulation2[,2:7] = AbunLenAgePopulation[, 3:8]
	AbunLenAgePopulation2[,8] = rowSums(AbunLenAgePopulation[, 9:ncol(AbunLenAgePopulation)])

	ALKpopulation = calc_ALK(x = AbunLenAgePopulation2)

	png(paste0('ALKPopulation_', scenarioName, '_CV1_', CV1, '_CV2_', CV2, '.png'), height = 550, width = 700, units = 'px', res = 130)

		par(mar = c(4,4,0.5, 1))
		image.plot(t(ALKpopulation), axes = FALSE, xlab = 'Ages', ylab = 'Length (cm)', legend.lab = 'Proportion', legend.line = 2.8)
		axis(2, at = seq(0, 1, length.out = 5), labels = floor(seq(minLen, maxLen, length.out = 5)), las = 2)
		axis(1, at = seq(0, 1, length.out = agePlus), labels = seq(minEstAge, agePlus, by = 1))

	dev.off()

}