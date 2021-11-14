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
	float stockCUpdateFreq <- 1.0 #day;
	float biophysicalProcessesUpdateFreq <- 1.0 #day;
	float outputsComputationFreq <- 1.0 #week;
	float endDate <- 1.0 #month; // Dry season length
	bool stopSim <- false;

	// Inequalities exploration
	string parcelDistrib <- "GiniVect" among: ["Equity", "NormalDist", "GiniVect"];
	// string herdDistrib among: ["Equity", "NormalDist", "GiniVect"];
	list
	vectGiniSizes <- [245.5464833043038, 223.35747861582468, 95.75988953731928, 19.694767606581188, 110.7781965225174, 46.88895560645675, 141.48199067354747, 172.5826868101815, 231.97740788005905, 9.871634884541091, 9.980317711513598, 189.60356034916396, 230.5794871128019, 111.98544942032184, 181.26810273182724, 6.837416752789971, 179.4094959828462, 104.81068646683968, 73.73521981433268, 256.08396935310486, 52.37841746146464, 273.2775951183603, 118.93572216394037, 45.46953291226, 110.10223790633351, 150.11558087052376, 22.92408602725342, 220.2242853801002, 108.27243846005584, 213.51610716946513, 210.6986574945393, 159.45299884611688, 223.43773945927688, 15.293668565456498, 13.774570249100314, 250.17096097992382, 17.41330935111912, 217.20640070266782, 251.99990676922263, 46.53036965480257, 27.806026442490108, 56.940073644609036, 92.57993480148107, 242.25521934025633, 74.62640333667417, 147.42470305356966, 41.030544567096825, 45.07551916990127, 114.2870833562322, 154.62442500469064, 46.43486791037341, 164.36487519990246, 227.55416263944795, 157.12951857634033, 30.124848550431725, 81.20375731041172, 5.0959688362942295, 47.15433817937703, 63.609650548908526, 15.733887926038815, 146.81304571644634, 72.15775599839755, 5.123123636609705, 162.91287827641327, 97.29873703245046, 30.36026663653687, 34.10023030372773, 169.52736124267406, 58.55853914962734, 5.15824281560584, 22.694923819657063, 250.05700994803976, 164.51106795184072, 93.57823912302536, 142.12801911925314, 175.9720196627706, 270.37131325650137, 38.84024391997657, 273.9720073474037, 57.07863104158608, 289.9677123537575, 244.61421284952254, 8.51579101234492, 292.1465592589691]; //TODO

	// landscape parameters
	float maxCropBiomassContentHa <- 351.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; weeds and crop residues
	float maxRangelandBiomassContentHa <- 375.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; grass and shrubs
	float maxCropBiomassContent <- maxCropBiomassContentHa * hectareToCell;
	float maxRangelandBiomassContent <- maxRangelandBiomassContentHa * hectareToCell;

	// Initiation
	init {
		write "Reading input raster";
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

		// Creating herds and paddock instantiation
		write "Placing paddocks, distribution : " + parcelDistrib;
		create herd number: nbHerdsInit;
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
							parcelSize <- float(vectGiniSizes[newParc]);
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
						if newParc mod 10 = 0 {
							write "	Paddocks placed : " + newParc;
						}

					}

				}

			}

			radiusIncrement <- radiusIncrement + cellWidth * 2;
			write "		Scanned radius : " + round(sqrt(nbHerdsInit) * cellWidth + radiusIncrement) + " m";
			assert radiusIncrement < sqrt(shape.height * shape.width); // Breaks the while loop
		}

		write "End of init";
	}

	// Weekly print
	reflex weekPrompt when: every(#week) {
		write string(date(time), "'Week 'w");
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
		write "Dry season over, end of the simulation";
		do computeENAIndicators;
		stopSim <- true;
		do pause;
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
