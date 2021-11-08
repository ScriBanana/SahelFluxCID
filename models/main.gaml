/**
* Name: SahelFlux
* Simplistic flux model for Sahel agropastoral agroecosystems. Computes carbon balance and ENA indicators over one dry season. 
* Author: AS
* Tags: 
*/
model SahelFlux

import "ImportZoning.gaml" // Sets the grid land uses according to a raster.
import "StockFlows.gaml" // Soil biophysical processes.
import "HerdsBehaviour.gaml" // Herds behaviour and movement.
import "ExperimentRun.gaml" // Experiment file
global {
//Simulation parameters
	float step <- 30.0 #minutes;
	float visualUpdate <- 1.0 #week; // For all but the main display
	float stockCUpdateFreq <- 1.0 #day;

	// landscape parameters
	float maxCropBiomassContent <- 2.0;
	float maxRangelandBiomassContent <- 10.0;

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

		// Paddock instantiation
		int newParc <- 0;
		float radiusIncrement <- 0.0;
		loop while: newParc < nbHerdsInit {
			loop cell over: shuffle(landscape where (each distance_to centroid(world) <= (sqrt(nbHerdsInit) * cellWidth + radiusIncrement) and each.cellLUSimple = "Cropland" and
			each.overlappingPaddock = nil)) {
				if empty((cell neighbors_at parcelSize where (each.overlappingPaddock != nil or each.cellLUSimple != "Cropland"))) { // Could probably be in the loop definition...
					if newParc < nbHerdsInit {
						create nightPaddock {

						// Plots attribution
							myOriginCell <- cell;
							myOriginCell.overlappingPaddock <- self;
							self.myCells <+ myOriginCell;
							location <- myOriginCell.location;
							ask (myOriginCell neighbors_at parcelSize) where (each.cellLUSimple = "Cropland" and each.overlappingPaddock = nil) {
								self.overlappingPaddock <- myself;
								myself.myCells <+ self;
								myself.nightsPerCellMap <+ self::0;
							}

							// Herds attribution
							ask one_of(herd where (each.myPaddock = nil)) {
								self.myPaddock <- myself;
								myself.myHerd <- self;
							}

							myHerd.currentSleepSpot <- one_of(self.myCells);
							myHerd.location <- myHerd.currentSleepSpot.location;
						}

						newParc <- newParc + 1;
						if newParc mod 10 = 0 {
							write "Paddocks placed : " + newParc;
						}

					} else {
						break;
					}

				}

			}

			radiusIncrement <- radiusIncrement + cellWidth;
			write "Radius increment : " + radiusIncrement;
		}

	}

}

grid landscape width: gridWidth height: gridHeight parallel: true neighbors: 8 {

// Land use
	string cellLU;
	string cellLUSimple;
	bool nonGrazable <- false;

	// Parcels
	nightPaddock overlappingPaddock <- nil;

	// Biomass and nutrients
	stockFlowMecanisms myStockFlowMecanisms;
	float biomassContent;

	reflex updateColour when: !nonGrazable {
		if cellLUSimple = "Cropland" {
			color <- rgb(255 + (216 - 255) / maxCropBiomassContent * biomassContent, 255 + (232 - 255) / maxCropBiomassContent * biomassContent, 180);
		} else if cellLUSimple = "Rangeland" {
			color <-
			rgb(200 + (101 - 200) / maxCropBiomassContent * biomassContent, 230 + (198 - 230) / maxCropBiomassContent * biomassContent, 180 + (110 - 180) / maxCropBiomassContent * biomassContent);
		}

	}

}

species nightPaddock {
	landscape myOriginCell;
	list<landscape> myCells;
	map<landscape, int> nightsPerCellMap;
	herd myHerd;

	aspect default {
		draw square(cellWidth / 2) color: myHerd.herdColour;
		ask myCells {
			draw square(cellWidth) color: #transparent border: myself.myHerd.herdColour;
		}

	}

}
