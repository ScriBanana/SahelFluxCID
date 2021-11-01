/**
* Name: SahelFlux
* Simplistic flux model for Sahel agropastoral agroecosystems. Computes carbon balance and ENA indicators over one dry season. 
* Author: AS
* Tags: sssdf
*/
model SahelFlux

import "ImportZoning.gaml"

global {
// landscape parameters
	int maxCropBiomassContent <- 5;
	int maxRangelandBiomassContent <- 5;
}

grid cropland parent: landscape {

	init {
		if cellLU = "Rainfed crops" {
			biomassContent <- rnd(maxCropBiomassContent);
		} else if cellLU = "Wooded savannah" {
			biomassContent <- rnd(maxRangelandBiomassContent);
		} else {
			biomassContent <- 0;
		}

	}

}

grid rangeland parent: landscape {

	init {
		biomassContent <- rnd(10);
	}

}

species herd {

	aspect default {
		draw square(2) color: #sandybrown;
	}

}

experiment simulation type: gui {
	parameter "Grid layout" var: gridLayout <- testImg among: [testImg, zoningReduitAudouin15Diohine, zoningAudouin15Barry, zoningAudouin15Diohine]; // Marche malgré l'exception.
	output {
		display visual1 type: java2D {
			grid landscape border: #lightgrey;
			species herd;
		}

		display diverseCharts refresh: every(10 #cycles) {
			chart "Total biomass evolution" type: series {
				data "Biomass" value: landscape sum_of (each.biomassContent);
			}

		}

	}

}