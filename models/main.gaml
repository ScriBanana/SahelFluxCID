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
	float endDate <- 8.0 #month; //8.0 #month; // Dry season length
	bool batchSim <- false;
	bool stopSim <- false;

	// Inequalities exploration
	string parcelDistrib <- "NormalDist" among: ["Equity", "NormalDist", "GiniVect"];
	string herdDistrib <- "NormalDist" among: ["Equity", "NormalDist", "GiniVect"];
	list<float> vectGiniParcels;
	list<float> vectGiniHerds;
	float GiniP;
	float GiniH;

	// landscape parameters
	float maxCropBiomassContentHa <- 351.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; weeds and crop residues
	float maxRangelandBiomassContentHa <- 375.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; grass and shrubs
	float maxCropBiomassContent <- maxCropBiomassContentHa * hectareToCell;
	float maxRangelandBiomassContent <- maxRangelandBiomassContentHa * hectareToCell;

	// Initiation
	init {
		if !batchSim { //TODO TEST - NE PAS PUSH
			parcelDistrib <- "GiniVect";
			herdDistrib <- "GiniVect";
			list<float>
			vectG19 <- [0.7786831180838535, 0.6895817921841056, 0.5017136317364046, 0.6408557076739017, 0.7454647318848511, 0.9096436505113219, 0.5849838074091138, 0.16125344087644589, 0.8672666856239937, 0.7085345639332985, 0.7460146712026432, 0.5770052172445581, 0.5402196722725016, 0.7096033502139134, 0.772741012807837, 0.7709449865937686, 0.6745762260288615, 0.8838393309127788, 0.6587717893372725, 0.4191937919684706, 0.8304319525372893, 0.4340595997842236, 0.7314242272897715, 0.7178791200831091, 0.948650062664229, 0.7923001295056998, 0.24189096988555592, 0.6019085206280698, 0.7078995830013193, 0.7020146139008816, 0.5188362774633007, 0.9988162756797522, 0.13021499311547602, 0.3524843222443599, 0.7204289731894389, 0.38569907992148744, 0.5892426897499047, 0.3016115374038716, 0.6111760365641272, 0.204067623029071, 0.7435217989099281, 0.7231469460574905, 0.5414487538669162, 0.42328255276589355, 0.5907003295616041, 0.29885819599368424, 0.6962602249032281, 0.4885667403055505, 0.43966979849681875, 0.1426338769639689, 0.8201867629880447, 0.7140990664131488, 0.9811523569841002, 0.6685746111265188, 0.44283400401858897, 0.5961602916156105, 0.3935571858826228, 0.09990278109347683, 0.4469557821086607, 0.6859374584293085, 0.6033519436382212, 0.8846038848696206, 0.7725190839748088, 0.555580715308789, 0.5567624152978554, 0.8214087775790235, 0.8424756120207093, 0.9519834053002945, 0.690045034108124, 0.7033477052607976, 0.40541802760264567, 0.740049030814281, 0.793555010506429, 0.8199776815295708, 0.4998208097503387, 0.9088878227451885, 0.42840692300722694, 0.00217469768728096, 0.8091021207476623, 0.57779720059288, 0.5615288017207469, 0.8428722799433198, 0.3691059846652761, 0.5994583823609339];
			list<float>
			vectG33 <- [0.6883105997472106, 0.9714616605356652, 0.9960835913355814, 0.7961614033062347, 0.5455070948893681, 0.9242734143606605, 0.4031602591979293, 0.02332913610517551, 0.5470125509281429, 0.06734860420141608, 0.9857053801985256, 0.5065533043361287, 0.7827663752347005, 0.6681046488677059, 0.8571375626722086, 0.06879427614062672, 0.407627998045372, 0.07075198446230657, 0.14370860726453183, 0.12414289070612172, 0.05240216136685827, 0.4600187770038663, 0.18758470592515064, 0.5186520432966327, 0.7188235666121934, 0.25864786989540833, 0.07395936432947836, 0.9560769980983739, 0.5828407818419061, 0.8919833905685328, 0.6912525847995398, 0.00059699914579237, 0.6081187847471294, 0.1517795311379807, 0.7697129021352946, 0.06449962808875165, 0.5237834253411737, 0.9899201328300338, 0.8566085128468369, 0.8256239567649092, 0.972273517698235, 0.37212779698865617, 0.5389806590314861, 0.00534337969626164, 0.2949805562891159, 0.3201601731071604, 0.8943025248813985, 0.6354350853377135, 0.4853040358162062, 0.42705085927466513, 0.05542989192763559, 0.509353493633961, 0.9356710608795652, 0.8617977001055027, 0.9539122839013726, 0.5689867785590514, 0.2850169074048394, 0.9002313582179343, 0.8151769193588929, 0.9172673440766913, 0.8392081457853999, 0.42722001405702903, 0.5128787924203849, 0.37195704132791174, 0.4217811693327117, 0.7017759860681996, 0.63153689033329, 0.25068451377927925, 0.4420518225376979, 0.6768402403110384, 0.1451161084635847, 0.4635462766742434, 0.23040955159154886, 0.06401513037631135, 0.9749487081600978, 0.4435572473510184, 0.3875328358866179, 0.8677149500080293, 0.25163813874059615, 0.07905125908708444, 0.8773249671376656, 0.2238718353270902, 0.9205612257972802, 0.5528730347466526];
			list<float>
			vectG48 <- [0.8095691294328794, 0.24050799152261848, 0.453999287291744, 0.9691379552555263, 0.9103245296573809, 0.44435609513595264, 0.7088252347267581, 0.5755016321996131, 0.08781153121548235, 0.04237902095959134, 0.00976636318693413, 0.08095769418054688, 0.04580015112681768, 0.00841951334319058, 0.6206017959074727, 0.06799591610977695, 0.6872798552072001, 0.09810974244419346, 0.8964692577975633, 0.5631216425606431, 0.25496405155088064, 0.02346373480910369, 0.01632603352238504, 0.24279037144479965, 0.49708266579676696, 0.00452231698912031, 0.29498340470855733, 0.05107782386354665, 0.31196459443367164, 0.8679803430289176, 0.07009006493436021, 0.0399800928845444, 0.3083662726526001, 0.00726919233882073, 0.0822787658759947, 0.6497260064942281, 0.21868526741431893, 0.4287632117683007, 0.8196807279841368, 0.10010134449180341, 0.4363723945038682, 0.203100065582566, 0.27372586509450914, 0.8758953360610064, 0.00368387186614028, 0.7977536066384986, 0.5851864069896323, 0.04139328685922539, 0.01863117665093894, 0.13336865565618095, 0.932972810119143, 0.32092797631545356, 0.09743458903605229, 0.6503032628648322, 0.5789825042619752, 0.8476668001307376, 0.06065006285420771, 0.1972386342242861, 0.06764432424101652, 0.14894353099404223, 0.04863562782565889, 0.6831554139507171, 0.20594366881658388, 0.8203232660376106, 0.21791516480787232, 0.8201031776820178, 0.8733853369793011, 0.20253425010959447, 0.49599252371839275, 0.08484292667906335, 0.35939097518904717, 0.2639517143893739, 0.7859281533045154, 0.8126084044966374, 0.9332957011308337, 0.34757295942337474, 0.23043401423379184, 0.1010444916528821, 0.04801482259576684, 0.6288537596604524, 0.02440559617960825, 0.00439888454198822, 0.08860766510045948, 0.8656380299342534];
			vectGiniParcels <- vectG33;
			vectGiniHerds <- vectG33;
			vectGiniParcels <- vectGiniParcels collect (each * meanParcelSize * 2);
			vectGiniHerds <- vectGiniHerds collect (each * meanHerdSize * 2);
		}

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
			write "		Input Gini herd control : " + gini(vectGiniHerds);
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

		// Paddock instantiation
 write "	Placing paddocks, distribution : " + parcelDistrib;
		if parcelDistrib = "GiniVect" {
			write "		Input Gini parcel control : " + gini(vectGiniParcels);
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
							self.paddockSize <- parcelSize;
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
		GiniP <- gini(nightPaddock collect each.paddockSize);
		GiniH <- gini(herd collect float(each.herdSize));
		write "		Gini control - GiniP : " + GiniP + ", GiniH : " + GiniH;
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
	map<float, float> depositedOMMap;
	float cumulDepositedOM;

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
	float paddockSize;

	aspect default {
		ask myCells {
			draw rectangle(cellWidth, cellHeight) color: #transparent border: myself.myHerd.herdColour;
		}

	}

}
