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
import "ComputeNfluxes.gaml" // N fluxes and ENA indicators.
import "ExperimentRun.gaml" // Experiment file
global {
//	// Simulation parameters
	float step <- 30.0 #minutes;
	float yearToStep <- step / 1.0 #year;
	float visualUpdate <- 1.0 #week; // For all but the main display
	//	float stockCUpdateFreq <- 1.0 #day;
	float biophysicalProcessesUpdateFreq <- 1.0 #day;
	float outputsComputationFreq <- 1.0 #week;
	float endDate <- 8.0 #month; // Dry season length
	bool batchSim <- false;
	bool stopSim <- false;

	// Inequalities exploration
	string parcelDistrib <- "NormalDist" among: ["Equity", "NormalDist", "GiniVect"];
	string herdDistrib <- "NormalDist" among: ["Equity", "NormalDist", "GiniVect"];
	list<float> vectGiniParcels;
	list<float> vectGiniHerds;
	// landscape parameters
	float maxCropBiomassContentHa <- 351.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; weeds and crop residues
	float maxRangelandBiomassContentHa <- 375.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; grass and shrubs
	float maxCropBiomassContent <- maxCropBiomassContentHa * hectareToCell;
	float maxRangelandBiomassContent <- maxRangelandBiomassContentHa * hectareToCell;

	// Initiation
	init {
		write "	Reading input raster";
		loop cell over: landscape {

		// LU attribution according to colour (see ImportZoning.gaml)
			rgb LURasterColour <- rgb(gridLayout at {cell.grid_x, cell.grid_y});
			rgb computedLUColour <- eucliClosestColour(LURasterColour, LUColourList);
			cell.cellLU <- LUList at (LUColourList index_of computedLUColour);

			// LU assignation
			if cell.cellLU = "Rainfed crops" or cell.cellLU = "Fallows" {
			//Random value for biomass and associated colour, based on LU
				cell.cellLUSimple <- "Cropland";
				cell.biomassContent <- maxCropBiomassContent - abs(gauss(0, maxCropBiomassContent / 20)); //sigma random
				cell.initialBiomassContent <- cell.biomassContent;
				//color <- rgb(216, 232, 180);
				cell.color <- rgb(255 + (216 - 255) / maxCropBiomassContent * cell.biomassContent, 255 + (232 - 255) / maxCropBiomassContent * cell.biomassContent, 180);

				// Link with own nutrientStocks instance
				create plotStockFlowMecanisms with: [myPlot::cell] {
					cell.myStockFlowMecanisms <- self;
				}

			} else if cell.cellLU = "Wooded savannah" or cell.cellLU = "Lowlands" {
			//Random value for biomass and associated colour, based on LU
				cell.cellLUSimple <- "Rangeland";
				cell.biomassContent <- maxRangelandBiomassContent - abs(gauss(0, maxRangelandBiomassContent / 10)); //sigma random
				cell.initialBiomassContent <- cell.biomassContent;
				//color <- rgb(101, 198, 110);
				cell.color <-
				rgb(200 + (101 - 200) / maxCropBiomassContent * cell.biomassContent, 230 + (198 - 230) / maxCropBiomassContent * cell.biomassContent, 180 + (110 - 180) / maxCropBiomassContent * cell.biomassContent);

				// Link with own nutrientStocks instance
				create plotStockFlowMecanisms with: [myPlot::cell] {
					cell.myStockFlowMecanisms <- self;
				}

			} else {
				cell.cellLUSimple <- "NonCrossable";
				cell.nonGrazable <- true;
				cell.color <- rgb(102, 102, 102);
			}

		}

		// Creating herds
		write "	Creating herds, distribution : " + herdDistrib;
		if herdDistrib = "GiniVect" {
			write "		Gini control : " + gini(vectGiniHerds);
		}

		if herdDistrib = "Equity" {
			create herd number: nbHerdsInit with: [herdSize::round(meanHerdSize)];
		} else {
			loop herdInd from: 0 to: nbHerdsInit - 1 {
				switch herdDistrib {
					match "NormalDist" {
						int gaussHerdSize <- -1;
						loop while: gaussHerdSize < 0 {
							gaussHerdSize <- round(gauss(meanHerdSize, SDHerdSize));
						}

						create herd with: [herdSize::gaussHerdSize];
					}

					match "GiniVect" {
						create herd with: [herdSize::round(vectGiniHerds[herdInd])];
					}

				}

			}

		}

		write "	NBHerds : " + herd sum_of each.herdSize;
		// Paddock instantiation
		write "	Placing paddocks, distribution : " + parcelDistrib;
		if parcelDistrib = "GiniVect" {
			write "		Gini control : " + gini(vectGiniParcels);
		}

		int newParc <- 0;
		float radiusIncrement <- 0.0;
		loop while: newParc < nbHerdsInit {
			loop cell over: shuffle(landscape where (each distance_to villageLocation <= (sqrt(nbHerdsInit) * cellWidth + radiusIncrement) and each.cellLUSimple = "Cropland")) {
				if cell.overlappingPaddock = nil {
					if newParc >= nbHerdsInit {
						break;
					}
					// Set parcel size according to inequality DoE
					float parcelSize;
					switch parcelDistrib {
						match "Equity" {
							parcelSize <- meanParcelSize;
						}

						match "NormalDist" {
							parcelSize <- -1.0;
							loop while: parcelSize < 0.0 {
								parcelSize <- gauss(meanParcelSize, SDParcelSize);
							}

						}

						match "GiniVect" {
							parcelSize <- float(vectGiniParcels[newParc]);
						}

					}

					if (parcelSize / 2 < min(cellHeight, cellWidth) / 2) or (empty((cell neighbors_at (parcelSize / 2) where (each.overlappingPaddock != nil or each.cellLUSimple !=
					"Cropland")))) { // Could probably be in the loop definition...
						create nightPaddock {
						// Plots attribution
							myOriginCell <- cell;
							myOriginCell.overlappingPaddock <- self;
							self.myCells <+ myOriginCell;
							self.nightsPerCellMap <+ myOriginCell::0;
							location <- myOriginCell.location;
							if parcelSize / 2 >= min(cellHeight, cellWidth) / 2 { // TODO fix to have 4 cells parcels some day
								ask myOriginCell neighbors_at (parcelSize / 2) where (each.cellLUSimple = "Cropland" and each.overlappingPaddock = nil) {
									self.overlappingPaddock <- myself;
									myself.myCells <+ self;
									myself.nightsPerCellMap <+ self::0;
								}

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
						if newParc mod 10 = 0 and !batchSim {
							write "		Paddocks placed : " + newParc;
						}

					}

				}

			}

			radiusIncrement <- radiusIncrement + cellWidth * 2;
			if !batchSim {
				write "			Scanned radius : " + round(sqrt(nbHerdsInit) * cellWidth + radiusIncrement) + " m";
			}

			assert radiusIncrement < sqrt(shape.height * shape.width); // Breaks the while loop
		}

		write "	End of init";
	}

	// Weekly print
	reflex weekPrompt when: every(#week) {
		write string(date(time), "'		Week 'w");
	}

	// Some global state variables
	float meanBiomassContent;
	float biomassContentSD;

	reflex updateSomeGlobalVariables when: every(biophysicalProcessesUpdateFreq) {

	//	// Aggregation of biomass content for herds behaviours
		list<float> allCellsBiomass;
		ask landscape where (!each.nonGrazable) {
			allCellsBiomass <+ self.biomassContent;
		}

		meanBiomassContent <- mean(allCellsBiomass); // Annoying but more efficient since there's no standard_deviation_of...
		biomassContentSD <- standard_deviation(allCellsBiomass);
	}

	// Break statement
	reflex endSim when: time > endDate {
		write "	End of simulation";
		do computeENAIndicators;
		if batchSim {
			stopSim <- true;
		} else {
			do pause;
		}

	}

}

grid landscape width: gridWidth height: gridHeight parallel: true neighbors: 8 {

//	// Land use
	string cellLU;
	string cellLUSimple;
	bool nonGrazable <- false;

	// Parcels
	nightPaddock overlappingPaddock <- nil;

	// Biomass and nutrients
	plotStockFlowMecanisms myStockFlowMecanisms;
	float biomassContent min: 0.0 max: max(maxCropBiomassContent, maxRangelandBiomassContent);
	float initialBiomassContent;
	map<float, float> depositedOMMap; // TODO Crop periodically to save memory space?

	// Colouring
	reflex updateColour when: !nonGrazable {
		if cellLUSimple = "Cropland" {
			color <- rgb(255 + (216 - 255) / maxCropBiomassContent * biomassContent, 255 + (232 - 255) / maxCropBiomassContent * biomassContent, 180);
		} else if cellLUSimple = "Rangeland" {
			color <-
			rgb(200 + (101 - 200) / maxRangelandBiomassContent * biomassContent, 230 + (198 - 230) / maxRangelandBiomassContent * biomassContent, 180 + (110 - 180) / maxRangelandBiomassContent * biomassContent);
		}

	}

}

species nightPaddock {
	landscape myOriginCell;
	list<landscape> myCells;
	map<landscape, int> nightsPerCellMap;
	herd myHerd;

	aspect default {
		ask myCells {
			draw rectangle(cellWidth, cellHeight) color: #transparent border: myself.myHerd.herdColour;
		}

	}

}
