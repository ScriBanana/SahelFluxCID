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
	int nbHerdsInit <- 50; //TODO Baser sur Myriam
	// Behaviour
	int wakeUpTime <- 8; // Time of the day at which animals are released in the morning (Own accelerometer data)
	int eveningTime <- 19; // Time of the day at which animals come back to their sleeping spot (Own accelerometer data)
	float herdSpeed <- 0.833; // m/s = 3 km/h Does not account for grazing speed due to scale. (Own GPS data)
	float herdVisionRadius <- 45.0 #m; //(Gersie, 2020)
	float goodSpotThreshold <- 10.0; // TODO random pour l'heure! Amount of biomass in herdVisionRadius for the spot to be deemed suitable ant the herd to stop and start grazing

	// Zootechnical data TODO ramener à l'échelle du tpx!!
	float dailyBiomassConsumed <- 5.8; // Maximum amount of biomass consumed daily. (Memento p. 1411 pour bovins adultes de 2 à 3 ans de 250 kg) TODO : bien en MS?
	float intakeRate <- 0.36; // Biomass eaten per time step (TODO complètement random, voir Chirat?)
	float digestionLength <- 10.0 #h; // TODO Duration of the digestion of biomass in the animals
	float ratioExcretionIngestion <- 0.55; // Dung excreted over ingested biomass (dry matter). Source : Wade (2016)

	// Paddocking
	int maxNbNightsPerCell <- 4; // Field data; TODO A PARAM selon le scale effectif; 3-4 jour en réalité
}

species herd control: fsm skills: [moving] {
	rgb herdColour <- rnd_color(255);

	// Paddocking parameters
	nightPaddock myPaddock <- nil;
	landscape currentSleepSpot;

	// Grazing parameters
	map<float, float> chymeChunksMap;
	float satietyMeter <- 0.0;
	bool hungry <- true update: (satietyMeter <= dailyBiomassConsumed);

	// FSM parameters
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
		do graze(currentGrazingCell);
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isResting when: !hungry;
		transition to: isChangingSite when: !isInGoodSpot;
	}

	state isResting {
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isGrazing when: hungry;
	}

	//// Functions ////
	list<landscape> checkSpotQuality { // and return visible cells
		list<landscape> cellsAround <- landscape at_distance (herdVisionRadius);
		isInGoodSpot <- cellsAround sum_of each.biomassContent > goodSpotThreshold ? true : false;
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
		float eatenBiomass <- intakeRate; // Adaptable if variable IIR are intruduced
		ask cellToGraze {
			self.biomassContent <- self.biomassContent - eatenBiomass;
		}

		chymeChunksMap <+ time::eatenBiomass;
		satietyMeter <- satietyMeter + eatenBiomass;
	}

	// Grange (2015), Wade (2016). Urine is computed in StockFlows.gaml
	reflex excrete when: !empty(chymeChunksMap) and chymeChunksMap.keys[0] + digestionLength > time {
		landscape currentCell <- one_of(landscape overlapping self);
		currentCell.depositedOMMap <+ time::(first(chymeChunksMap.values) * ratioExcretionIngestion);
		chymeChunksMap >- first(chymeChunksMap);
	}

	aspect default {
		draw square(sqrt(cellWidth ^ 2 / 2) * 0.8) rotated_by 45.0 color: herdColour border: #black;
	}

}

