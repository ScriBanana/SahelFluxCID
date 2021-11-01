/**
* Name: SahelFlux
* Simplistic flux model for Sahel agropastoral agroecosystems. Computes carbon balance and ENA indicators over one dry season. 
* Author: AS
* Tags: sssdf
*/
model SahelFlux

global {

	init {
	}

}

grid landscape {
	int biomassContent;
}

grid cropland parent: landscape {

	init {
		biomassContent <- rnd(2);
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