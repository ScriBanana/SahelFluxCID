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

//	// Nitrogen
	float initialSoilNStock <- 27.5; // kgN/ha (Grillot, 2018)
	float vegetalCroplandBiomassNContent <- 0.005; // kgN/kgDM (Balandier, 2017) TODO variations according to LU
	float vegetalRangelandBiomassNContent <- 0.009; // kgN/kgDM (Balandier, 2017) TODO variations according to LU
	float fecesNContent <- 0.0238; // kgN/ kg excreted dry matter (INRA, 2018 - overall mean on BoviDig; coherent with Balandier, 2017) TODO Fit to area
	float ratioUrineNFecesN <- 0.25; // Wade, 2016
	float atmoNFixationHaYear <- 25.0; // kgN/ha/year Grillot (2018) -> soil microorg, trees, rhizobiums; gross estimate TODO refine
	float excretionsNEmissionFact <- 0.25; // kgN emitted / kgN applied (Balandier, 2017)
	float urineNEmissionFact <- 0.45; // kgN emitted / kgN applied (Balandier, 2017)

	// Carbon
	//	float propLabileCFixed <- 0.005; //TODO PARAM ! selon LU?
	//	float propLabileCMineralised <- 0.05; //TODO PARAM
	//	float propStableCMineralised <- 0.001; //TODO PARAM !!SP!!

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
		if myPlot.cellLUSimple = "Cropland" {
			periodNUptake <- lastPeriodBMUptake * vegetalCroplandBiomassNContent; // kgN/step
		} else if myPlot.cellLUSimple = "Rangeland" {
			periodNUptake <- lastPeriodBMUptake * vegetalRangelandBiomassNContent; // kgN/step
		}

		// Excretions
		float periodOMIntake <- 0.0;
		loop OMDepositDate over: reverse(myPlot.depositedOMMap.keys sort each) {
			if OMDepositDate <= lastNitrogenUpdateDate {
				break;
			}

			periodOMIntake <- periodOMIntake + myPlot.depositedOMMap at OMDepositDate;
		}

		float periodExcretionsNIntake <- periodOMIntake * fecesNContent;
		float periodUrineNIntake <- periodExcretionsNIntake * ratioUrineNFecesN;
		periodNIntake <- periodExcretionsNIntake + periodUrineNIntake; // kgN/step

		// Atmospheric fixation
		periodAtmoNFix <- atmoNFixationHaYear * yearToStep * hectareToCell; // kgN/step

		// Emissions : Grillot (2018)
		float previousPeriodExcretionEmissions <- periodExcretionsNIntake * excretionsNEmissionFact;
		float previousPeriodUrineEmissions <- periodUrineNIntake * urineNEmissionFact;
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
	//	float soilCInput <- 0.1; //TODO PARAM
	//	float labileCStock <- 2.0; //TODO PARAM
	//	float stableCStock <- 5.0; //TODO PARAM
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

	// OMDeposit
	aspect OMDeposited {
		float OMColourValue <- 2 * (255 / (1 + exp(-sum(myPlot.depositedOMMap.values)))) - 255; // Random 45.
		rgb OMColor <- rgb(255 - OMColourValue, 255 - OMColourValue, 255);
		draw square(cellWidth) color: OMColor;
	}

}

