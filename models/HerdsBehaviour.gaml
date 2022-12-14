/**
* Name: HerdsBehaviour
* In: SahelFlux
* Herd behaviours as a finite state machine, based on Zampaligré (2012), Gersie (2020), Wade (2016)
* Author: AS
* Tags: 
*/
model HerdsBehaviour

import "main.gaml"

global {
	int nbHerdsInit <- 84; // (Grillot et al, 2018)
	float meanHerdSize <- 3.7; // Tropical livestock unit (TLU) - cattle and small ruminants (Grillot et al, 2018)
	float SDHerdSize <- 0.2; // TLU (Grillot et al, 2018)
	// Behaviour
	int wakeUpTime <- 8;
	// Time of the day (24h) at which animals are released in the morning (Own accelerometer data)
	int eveningTime <- 19;
	// Time of the day (24h) at which animals come back to their sleeping spot (Own accelerometer data)
	float herdSpeed <- 0.833;
	// m/s = 3 km/h Does not account for grazing speed due to scale. (Own GPS data)
	float herdVisionRadius <- 20.0 #m; // (Gersie, 2020)

	// Zootechnical data
	float dailyIntakeRatePerTLU <- 4.65; // kgDM/TLU/day Maximum amount of biomass consumed daily. (Wade, 2016, fits with Chirat et al. 2014) Jonathan : 6.25 = 2.5 kgMS/kgPV * 250 (Paulo)
	float IIRRangelandTLU <- 14.2; // instantaneous intake rate; g DM biomass eaten per minute (Chirat et al, 2014)
	float IIRCroplandTLU <- 10.9;
	// instantaneous intake rate; g DM biomass eaten per minute (Chirat et al, 2014)
	float digestionLength <- 20.0 #h;
	// Duration of the digestion of biomass in the animals (expert knowledge -> ref ou préciser?)
	float ratioExcretionIngestion <- 0.55;
	// Dung excreted over ingested biomass (dry matter). Source : Wade (2016)

	// Paddocking
	int maxNbNightsPerCell <- 4; // Field data; TODO A PARAM selon le scale effectif; 3-4 jour en réalité
}

species herd control: fsm skills: [moving] {
	rgb herdColour <- rnd_color(255);
	int herdSize min: 1; // TLU


	// Paddocking parameters and variables
	nightPaddock myPaddock <- nil;
	landscape currentSleepSpot;

	// Grazing parameters and variables
	float dailyIntakeRatePerHerd <- dailyIntakeRatePerTLU * herdSize;
	float IIRRangelandHerd <- IIRRangelandTLU / 1000 * step / #minute * herdSize;
	float IIRCroplandHerd <- IIRCroplandTLU / 1000 * step / #minute * herdSize;
	list chymeChunksMap;
	float satietyMeter <- 0.0;
	bool hungry <- true update: (satietyMeter <= dailyIntakeRatePerHerd);
	landscape currentCell update: one_of(landscape overlapping self);

	// FSM parameters and variables
	// Sleep time in between globals wakeUpTime and eveningTime
	bool sleepTime <- true update: !(abs(current_date.hour - (eveningTime + wakeUpTime - 1) / 2) < (eveningTime - wakeUpTime - 1) / 2);
	landscape targetCell <- one_of(landscape where !each.nonGrazable);
	bool isInGoodSpot <- false;

	init {
		speed <- herdSpeed;
	}

	//// FSM behaviour ////
	state isGoingToSleepSpot {
		do goto target: currentSleepSpot;
		transition to: isSleepingInPaddock when: location overlaps currentSleepSpot.location;
	}

	state isSleepingInPaddock initial: true {
		enter {
			satietyMeter <- 0.0;
		}

		transition to: isChangingSite when: !sleepTime;
		exit {
			do updatePaddock;
		}

	}

	state isChangingSite {
		enter {
			targetCell <- one_of(landscape where (each.cellLUSimple = "Rangeland")); // TODO A affiner selon le DOE
		}

		do checkSpotQuality;

		//do wander amplitude: 90.0;
		do goto target: targetCell;
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isGrazing when: isInGoodSpot;
	}

	state isGrazing {
		enter {
			landscape currentGrazingCell <- one_of(landscape overlapping self);
		}

		list<landscape> cellsAround <- checkSpotQuality();
		if currentGrazingCell.biomassContent < cellsAround mean_of each.biomassContent { // TODO Bon, à voir...
			landscape juiciestCellAround <- one_of(cellsAround with_max_of (each.biomassContent));
			currentGrazingCell <- juiciestCellAround;
		}

		do goto target: currentGrazingCell;
		do graze(currentGrazingCell); // Add conditionnal if speed*step gets significantly reduced
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isResting when: !hungry;
		transition to: isChangingSite when: !isInGoodSpot;
	}

	state isResting {
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isGrazing when: hungry;
	}

	//// Functions ////
	list<landscape> checkSpotQuality { // and return visible cells.
		list<landscape> cellsAround <- landscape at_distance herdVisionRadius; // TODO Seems to cause slow down
		float goodSpotThreshold <- meanBiomassContent - biomassContentSD; // Gersie, 2020
		isInGoodSpot <- cellsAround mean_of each.biomassContent > goodSpotThreshold;
		return cellsAround;
	}

	// Change tile in the paddock parcel when maximum number of nights is reached.
	action updatePaddock {
		myPaddock.nightsPerCellMap[currentSleepSpot] <- myPaddock.nightsPerCellMap[currentSleepSpot] + 1;

		// When all tiles were occupied, reset the counter (TODO fit to reality)
		if sum(myPaddock.nightsPerCellMap.values) = length(myPaddock.nightsPerCellMap) * maxNbNightsPerCell {
			ask myPaddock {
				self.nightsPerCellMap <- [];
				ask myCells {
					self.overlappingPaddock.nightsPerCellMap <+ self::0;
				}

			}

		}

		if myPaddock.nightsPerCellMap[currentSleepSpot] >= maxNbNightsPerCell {
			currentSleepSpot <- one_of(myPaddock.nightsPerCellMap.pairs where (each.value < maxNbNightsPerCell)).key;
		}

	}

	action graze (landscape cellToGraze) {
		float eatenBiomass <- currentCell.cellLUSimple = "Rangeland" ? IIRRangelandHerd : IIRCroplandHerd;
		ask cellToGraze {
			self.biomassContent <- self.biomassContent - eatenBiomass;
		}
		chymeChunksMap <+ [time, eatenBiomass, currentCell.cellLUSimple];
		satietyMeter <- satietyMeter + eatenBiomass;
	}

	// Grange (2015), Wade (2016). Urine is computed in StockFlows.gaml
	reflex excrete when: !empty(chymeChunksMap) and time - float(first(chymeChunksMap)[0]) > digestionLength {
		
		float excretedFeces <- float(first(chymeChunksMap)[1]) * ratioExcretionIngestion;
		
		currentCell.depositedOMMap <+ [time, excretedFeces, first(chymeChunksMap)[2]];
		chymeChunksMap >- first(chymeChunksMap);
	}

	aspect default {
		draw square(sqrt(cellWidth ^ 2 / 2) * 0.8) rotated_by 45.0 color: herdColour border: #black;
	}

}

