/**
* Name: StockFlows
* In: SahelFlux 
* Soil biophysical mechanisms and variables
* Author: AS
* Tags: 
*/
model StockFlows

import "main.gaml"

global {

// Biophysical parameters
//// Carbon
//	float propLabileCFixed <- 0.005; //TODO A PARAM ! selon LU?
//	float propLabileCMineralised <- 0.05; //TODO A PARAM
//	float propStableCMineralised <- 0.001; //TODO A PARAM !!SP!!

// Nitrogen
	float initialSoilNStock <- 27.5; // kgN/ha (Grillot, 2018)
	float vegetalBiomassNContent <- 0.1; // kgN/kgDM TODO sourcer + varier selon LU
	float fecesNContent <- 0.0238; // kgN/ kg excreted dry matter (INRA, 2018 - overall mean on BoviDig) TODO Fit to area
	float atmoNFixationHaYear <- 25.0; // kgN/ha/year Grillot (2018) -> soil microorg, trees, rhizobiums; gross estimate TODO refine
	float excretionsNEmissionFact <- 0.2; // kgN emitted / kgN applied (Grillot, 2018)
	float urineNEmissionFact <- 0.6; // kgN emitted / kgN applied (Grillot, 2018)

}

species plotStockFlowMecanisms parallel: true { // Likely more efficient than with a 'reflex when: !nonGrazable' in the grid.
	landscape myPlot;

	init {
		location <- myPlot.location; // Looks like it has a random location otherwise, so I might as well
	}

	// Nitrogen
	float cellNstock <- initialSoilNStock * hectareToCell;
	float lastNitrogenUpdateDate <- time;
	float previousPeriodBiomass <- myPlot.biomassContent;
	float periodNUptake;
	float periodNIntake;
	float periodAtmoNFix;
	float periodSoilNEmissions;

	reflex updateNitrogenFlowsAndStock when: every(nitrogenFlowsUpdateFreq) {
	// 	// Uptake
		float lastPeriodBMUptake <- myPlot.biomassContent - previousPeriodBiomass;
		previousPeriodBiomass <- myPlot.biomassContent;
		periodNUptake <- lastPeriodBMUptake * vegetalBiomassNContent; // kgN/step

		// Excretions
		float periodOMIntake <- 0.0;
		loop OMDepositDate over: reverse(myPlot.depositedOMMap.keys sort each) {
			if OMDepositDate <= lastNitrogenUpdateDate {
				break;
			}

			periodOMIntake <- periodOMIntake + myPlot.depositedOMMap at OMDepositDate;
		}

		float periodExcretionsNIntake <- periodOMIntake * fecesNContent;
		float periodUrineNIntake <- 0.0;
		if periodOMIntake != 0.0 {
			periodUrineNIntake <- periodExcretionsNIntake / (1 / (0.2371 * ln(periodOMIntake * vegetalBiomassNContent) - 0.6436) - 1); // Grange (2015) - goes negative outside of the range of the regression

		}

		periodNIntake <- periodExcretionsNIntake + periodUrineNIntake; // kgN/step

		// Atmospheric fixation
		periodAtmoNFix <- atmoNFixationHaYear * yearToStep * hectareToCell; // kgN/step

		// Emissions : Grillot (2018)
		float previousPeriodExcretionEmissions <- periodExcretionsNIntake * excretionsNEmissionFact;
		float previousPeriodUrineEmissions <- periodExcretionsNIntake * excretionsNEmissionFact;
		periodSoilNEmissions <- previousPeriodExcretionEmissions + previousPeriodUrineEmissions; // kgN/step

		// Stock update
		cellNstock <- cellNstock - periodNUptake + periodNIntake + periodAtmoNFix - periodSoilNEmissions;

		//
		lastNitrogenUpdateDate <- time;
	}

	aspect nitrogenStock {
		float nitrogenColourValue <- 255 * (1 - 1 / (1 + exp(initialSoilNStock * hectareToCell - cellNstock))); // Pretty sigmoid with infection at starting value.
		rgb nitrogenColor <- rgb(255, nitrogenColourValue, nitrogenColourValue);
		draw square(cellWidth) color: nitrogenColor;
	}

	//	// 2 compartments carbon kinetic (based on ICBM; Andrén and Kätterer, 1997)
	//	float soilCInput <- 0.1; //TODO A PARAM
	//	float labileCStock <- 2.0; //TODO A PARAM
	//	float stableCStock <- 5.0; //TODO A PARAM
	//	float totalCStock <- labileCStock + stableCStock;
	//
	//	reflex updateCStocks when: every(stockCUpdateFreq) {
	//		float labileCStockBuffer <- labileCStock;
	//		labileCStock <- labileCStockBuffer * (1 - propLabileCMineralised - propLabileCFixed) + soilCInput;
	//		stableCStock <- stableCStock * (1 - propStableCMineralised) + labileCStockBuffer * propLabileCFixed;
	//		totalCStock <- labileCStock + stableCStock;
	//	}
	//
	//	aspect carbonStock {
	//		float carbonColourValue <- 255 * (1 - 1 / exp(10 - totalCStock)); // Pretty sigmoid; parameters a bit random.
	//		rgb carbonColor <- rgb(carbonColourValue, carbonColourValue, carbonColourValue);
	//		draw square(cellWidth) color: carbonColor;
	//	}

}

grid secondaryGrid width: gridWidth height: gridHeight parallel: true;
