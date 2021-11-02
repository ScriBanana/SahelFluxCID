/**
* Name: SahelFlux
* Simplistic flux model for Sahel agropastoral agroecosystems. Computes carbon balance and ENA indicators over one dry season. 
* Author: AS
* Tags: 
*/
model SahelFlux

import "ImportZoning.gaml"

global {
//Simulation parameters
	float step <- 30.0 #minutes;
	float visualUpdate <- 1.0 #day;
	float stockCUpdateFreq <- 1.0 #day;

	// landscape parameters
	int maxCropBiomassContent <- 2;
	int maxRangelandBiomassContent <- 10;

	// Biophysical parameters
	float propLabileCFixed <- 0.005; // A PARAM
	float propLabileCMineralised <- 0.05; // A PARAM
	float propStableCMineralised <- 0.001; // A PARAM !!SP!!

	// Herds parameters
	int nbHerdsInit <- 50;

	// Initiation
	init {
		loop cell over: landscape {

		// LU attribution according to colour (see ImportZoning.gaml)
			rgb LURasterColour <- rgb(gridLayout at {cell.grid_x, cell.grid_y});
			rgb computedLUColour <- eucliClosestColour(LURasterColour, LUColourList);
			cell.cellLU <- LUList at (LUColourList index_of computedLUColour);

			// LU assignation
			if cell.cellLU = "Rainfed crops" or cell.cellLU = "Fallows" {
			//Random value for biomass and associated colour, based on LU
				cell.cellLUSimple <- "Cropland";
				cell.biomassContent <- rnd(maxCropBiomassContent);
				//color <- rgb(216, 232, 180);
				cell.color <- rgb(255 + (216 - 255) / maxCropBiomassContent * cell.biomassContent, 255 + (232 - 255) / maxCropBiomassContent * cell.biomassContent, 180);

				// Link with own nutrientStocks instance
				create stockFlowMecanisms with: [myPlot::cell] {
					cell.myStockFlowMecanisms <- self;
				}

			} else if cell.cellLU = "Wooded savannah" or cell.cellLU = "Lowlands" {
			//Random value for biomass and associated colour, based on LU
				cell.cellLUSimple <- "Rangeland";
				cell.biomassContent <- rnd(maxRangelandBiomassContent);
				//color <- rgb(101, 198, 110);
				cell.color <-
				rgb(200 + (101 - 200) / maxCropBiomassContent * cell.biomassContent, 230 + (198 - 230) / maxCropBiomassContent * cell.biomassContent, 180 + (110 - 180) / maxCropBiomassContent * cell.biomassContent);

				// Link with own nutrientStocks instance
				create stockFlowMecanisms with: [myPlot::cell] {
					cell.myStockFlowMecanisms <- self;
				}

			} else {
				cell.cellLUSimple <- "NonCrossable";
				cell.nonGrazable <- true;
				cell.color <- #grey;
			}

		}

		create herd number: nbHerdsInit;
	}

}

grid landscape width: gridWidth height: gridHeight parallel: true {

// Land use
	string cellLU;
	string cellLUSimple;
	bool nonGrazable <- false;

	// Biomass and nutrients
	stockFlowMecanisms myStockFlowMecanisms;
	int biomassContent;

	reflex updateColour when: !nonGrazable and every(visualUpdate) {
		if cellLUSimple = "Cropland" {
			color <- rgb(255 + (216 - 255) / maxCropBiomassContent * biomassContent, 255 + (232 - 255) / maxCropBiomassContent * biomassContent, 180);
		} else if cellLUSimple = "Rangeland" {
			color <-
			rgb(200 + (101 - 200) / maxCropBiomassContent * biomassContent, 230 + (198 - 230) / maxCropBiomassContent * biomassContent, 180 + (110 - 180) / maxCropBiomassContent * biomassContent);
		}

	}

}

species stockFlowMecanisms parallel: true { // Likely more efficient than with a 'reflex when: !nonGrazable' in the grid.
	landscape myPlot;
	float soilNitrogenContent;
	float plantNitrogenContent;

	// 2 compartments carbon kinetic (based on ICBM; Andrén and Kätterer, 1997)
	float soilCInput <- 0.1; // A PARAM
	float labileCStock <- 2.0; // A PARAM
	float stableCStock <- 5.0; // A PARAM
	float totalCStock <- labileCStock + stableCStock;

	reflex updateCStocks when: every(stockCUpdateFreq) {
		float labileCStockBuffer <- labileCStock;
		labileCStock <- labileCStockBuffer * (1 - propLabileCMineralised - propLabileCFixed) + soilCInput;
		stableCStock <- stableCStock * (1 - propStableCMineralised) + labileCStockBuffer * propLabileCFixed;
		totalCStock <- labileCStock + stableCStock;
	}

	aspect carbonStock {
		location <- myPlot.location;
		float carbonColourValue <- 255 * (1 - 1 / exp(10 - totalCStock));
		rgb carbonColor <- rgb(carbonColourValue);
		draw square(1) color: carbonColor;
	}

	aspect nitrogenStock {
	}

}

species herd skills: [moving] {

	reflex herdMovement {
		do wander;
	}

	aspect default {
		draw square(2) color: #sandybrown;
	}

}

grid secondaryGrid width: gridWidth height: gridHeight parallel: true;

experiment simulation type: gui {
	parameter "Grid layout" var: gridLayout among: [testImg2, testImg, zoningReduitAudouin15Diohine]; //, zoningAudouin15Barry, zoningAudouin15Diohine]; // Marche malgré l'exception.
	output {
		display mainDisplay type: java2D {
			grid landscape;
			species herd;
		}

		display carbonDisplay type: java2D refresh: every(visualUpdate) {
			grid secondaryGrid border: #lightgrey;
			species stockFlowMecanisms aspect: carbonStock;
		}

		display plantBiomassChart refresh: every(visualUpdate) {
			chart "Total plant biomass evolution" type: series {
				data "Plant biomass" value: landscape sum_of (each.biomassContent);
			}

		}

		display carbonStocksChart refresh: every(visualUpdate) {
			chart "Soil organic carbon evolution" type: series {
				data "Total stock" value: stockFlowMecanisms sum_of (each.totalCStock);
				data "Labile stock" value: stockFlowMecanisms sum_of (each.labileCStock);
				data "Stable stock" value: stockFlowMecanisms sum_of (each.stableCStock);
			}

		}

	}

}