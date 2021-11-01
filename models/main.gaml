/**
* Name: SahelFlux
* Simplistic flux model for Sahel agropastoral agroecosystems. Computes carbon balance and ENA indicators over one dry season. 
* Author: AS
* Tags: sssdf
*/
model SahelFlux

import "ImportZoning.gaml"

global {
//Simulation parameters
	int visualUpdate <- 20;
	float step <- 30.0 #minutes;

	// landscape parameters
	int maxCropBiomassContent <- 2;
	int maxRangelandBiomassContent <- 10;

	// Herds parameters
	int nbHerdsInit <- 50;

	// Initiation
	init {
		create herd number: nbHerdsInit;
	}

}

grid landscape width: gridWidth height: gridHeight parallel: true {
	string cellLU;
	string cellLUSimple;
	bool nonGrazable <- false;
	int biomassContent;
	int colorValue;

	reflex updateColour when: !nonGrazable and every(visualUpdate) {
		if cellLUSimple = "Cropland" {
			color <- rgb(255 + (216 - 255) / maxCropBiomassContent * biomassContent, 255 + (232 - 255) / maxCropBiomassContent * biomassContent, 180);
		} else if cellLUSimple = "Rangeland" {
			color <-
			rgb(200 + (101 - 200) / maxCropBiomassContent * biomassContent, 230 + (198 - 230) / maxCropBiomassContent * biomassContent, 180 + (110 - 180) / maxCropBiomassContent * biomassContent);
		}

	}

}

species herd skills: [moving] {

	aspect default {
		draw square(2) color: #sandybrown;
	}

}

experiment simulation type: gui {
	parameter "Grid layout" var: gridLayout <- testImg among: [testImg, zoningReduitAudouin15Diohine]; //, zoningAudouin15Barry, zoningAudouin15Diohine]; // Marche malgré l'exception.
	output {
		display visual1 type: java2D {
			grid landscape;
			species herd;
		}

		display diverseCharts refresh: every(10 #cycles) {
			chart "Total biomass evolution" type: series {
				data "Biomass" value: landscape sum_of (each.biomassContent);
			}

		}

	}

}