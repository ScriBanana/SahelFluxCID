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
// Herds parameters
	int nbHerdsInit <- 50; // Baser sur Myriam
	int wakeUpTime <- 8; // Time of the day at which animals are released in the morning (Own accelerometer data)
	int eveningTime <- 19; // Time of the day at which animals come back to their sleeping spot (Own accelerometer data)
	float dailyBiomassConsumed <- 5.8; // Maximum amount of biomass consumed daily. (Memento p. 1411 pour bovins adultes de 2 à 3 ans de 250 kg)
	float fiveMinIntake <- 0.06; // Biomass eaten per 5 min (complètement random)
}

species herd control: fsm skills: [moving] {
	rgb herdColour <- rnd_color(255);
	nightPaddock myPaddock <- nil;
	// Sleep time in between wakeUpTime and eveningTime
	bool sleepTime <- true update: !(abs(current_date.hour - (eveningTime + wakeUpTime - 1) / 2) < (eveningTime - wakeUpTime - 1) / 2) every (#hour);
	float satietyMeter <- 0.0;
	bool hungry <- true update: (satietyMeter <= dailyBiomassConsumed);
	bool isInGoodSpot <- false;

	// FSM
	state isGoingToSleepSpot {
		enter {
			float sleepTimeAwarenessMoment <- time; // Timer pour voir
		}

		transition to: isSleepingInParcel when: ((time - sleepTimeAwarenessMoment) > 2000); // when: location

	}

	state isSleepingInParcel initial: true {
		enter {
			satietyMeter <- 0.0;
		}

		transition to: isChangingSite when: !sleepTime;
	}

	state isChangingSite {
		enter {
			float goodSpotOMeter <- time;
		}

		isInGoodSpot <- (time - goodSpotOMeter) > 2000;
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

	aspect default {
		draw circle(1) color: herdColour border: #black;
	}

}

