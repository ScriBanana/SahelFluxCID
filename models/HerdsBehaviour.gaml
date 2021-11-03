/**
* Name: HerdsBehaviour
* In: SahelFlux
* Herd behaviours as a finite state machine, based on Zampaligré (2012)
* Author: AS
* Tags: 
*/
model HerdsBehaviour

import "main.gaml"

global {
	int nbHerdsInit <- 50; //@ Baser sur Myriam
	// Behaviour
	int wakeUpTime <- 8; // Time of the day at which animals are released in the morning (Own accelerometer data)
	int eveningTime <- 19; // Time of the day at which animals come back to their sleeping spot (Own accelerometer data)
	float herdSpeed <- 0.833; // m/s = 3 km/h Does not account for grazing speed due to scale. (Own GPS data)
	// Zootechnical data
	float dailyBiomassConsumed <- 5.8; // Maximum amount of biomass consumed daily. (Memento p. 1411 pour bovins adultes de 2 à 3 ans de 250 kg)
	float fiveMinIntake <- 0.06; // Biomass eaten per 5 min (complètement random)

	// Paddocking
	int maxNbNightsPerCell <- 4; // Field data; @ A PARAM !
}

species herd control: fsm skills: [moving] {
	rgb herdColour <- rnd_color(255);

	// Paddocking
	nightPaddock myPaddock <- nil;
	landscape currentSleepSpot;

	// FSM behaviour
	// Sleep time in between wakeUpTime and eveningTime
	bool sleepTime <- true update: !(abs(current_date.hour - (eveningTime + wakeUpTime - 1) / 2) < (eveningTime - wakeUpTime - 1) / 2) every (#hour);
	float satietyMeter <- 0.0;
	bool hungry <- true update: (satietyMeter <= dailyBiomassConsumed);
	landscape currentGrazingCell <- one_of(landscape where !each.nonGrazable);
	bool isInGoodSpot <- false;

	// FSM
	state isGoingToSleepSpot {
		enter {
			int sleepTimeAwarenessMoment <- cycle; //@ Timer pour voir
		}

		do goto target: currentSleepSpot speed: herdSpeed;
		transition to: isSleepingInPaddock when: ((cycle - sleepTimeAwarenessMoment) > 14); // when: location

	}

	state isSleepingInPaddock initial: true {
		enter {
			satietyMeter <- 0.0;
		}

		transition to: isChangingSite when: !sleepTime;
		exit {
			myPaddock.nightsPerCellMap[currentSleepSpot] <- myPaddock.nightsPerCellMap[currentSleepSpot] + 1;
			if myPaddock.nightsPerCellMap[currentSleepSpot] > maxNbNightsPerCell {
				currentSleepSpot <- one_of(myPaddock.nightsPerCellMap.pairs where (each.value < maxNbNightsPerCell)).key;
			}
			///////@ GERER LE MOMENT OU TOUT EST FULL!!
		}

	}

	state isChangingSite {
		enter {
			currentGrazingCell <- one_of(landscape where !each.nonGrazable); // @A affiner selon le DOE
			int goodSpotOMeter <- cycle;
		}

		do goto target: currentGrazingCell speed: herdSpeed;
		isInGoodSpot <- (cycle - goodSpotOMeter) > 5;
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isGrazing when: isInGoodSpot;
	}

	state isGrazing {
		enter {
		}

		satietyMeter <- satietyMeter + fiveMinIntake;
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isResting when: !hungry;
		transition to: isChangingSite when: !isInGoodSpot;
	}

	state isResting {
		enter {
		}

		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isChangingSite when: !isInGoodSpot;
		transition to: isGrazing when: hungry;
	}

	reflex checkSpotQuality when: state in ["isChangingSite", "isGrazing"] {
	}

	aspect default {
		draw square(sqrt(cellWidth ^ 2 / 2) * 0.8) rotated_by 45.0 color: herdColour border: #black;
	}

}

