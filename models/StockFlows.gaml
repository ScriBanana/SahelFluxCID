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
 float vegetalCroplandBiomassNContent <- 0.005;
	// kgN/kgDM (Balandier, 2017) TODO variations according to LU
 float vegetalRangelandBiomassNContent <- 0.009; // kgN/kgDM (Balandier, 2017) TODO variations according to LU

	float fecesNContent <- 0.0238; // kgN/ kg excreted dry matter (INRA, 2018 - overall mean on BoviDig; coherent with Balandier, 2017) TODO Fit to area
 float
	ratioUrineNFecesN <- 0.25; // Wade, 2016
 float atmoNFixationHaYear <- 25.0; // kgN/ha/year Grillot (2018) -> soil microorg, trees, rhizobiums; gross estimate TODO refine
 float
	excretionsNEmissionFact <- 0.25; // kgN emitted / kgN applied (Balandier, 2017)
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
 float cellNstock <- initialSoilNStock * hectareToCell min: 0.0;
	float lastNitrogenUpdateDate <- time;
	float previousPeriodBiomass <- myPlot.biomassContent;
	float previousPeriodNStock <- cellNstock;
	float periodVarCellNstock;
	float periodNUptake;
	float periodNIntake;
	float periodAtmoNFix;
	float periodSoilNEmissions;
	map<string, float> cellNFluxMatrix <- ["periodVarCellNstock"::0.0, "periodNUptake"::0.0, "periodNIntake"::0.0, "periodAtmoNFix"::0.0, "periodSoilNEmissions"::0.0];

	reflex updateNitrogenFlowsAndStock when: every(biophysicalProcessesUpdateFreq) {

	// 	// Uptake
 float lastPeriodBMUptake <- abs(myPlot.biomassContent - previousPeriodBiomass);
		previousPeriodBiomass <- myPlot.biomassContent;
		if myPlot.cellLUSimple = "Cropland" {
			periodNUptake <- lastPeriodBMUptake * vegetalCroplandBiomassNContent; // kgN/step
 } else if myPlot.cellLUSimple = "Rangeland" {
			periodNUptake <- lastPeriodBMUptake * vegetalRangelandBiomassNContent; // kgN/step
 }

		cellNFluxMatrix["periodNUptake"] <- cellNFluxMatrix["periodNUptake"] + periodNUptake;

		// Excretions (intake)
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
 cellNFluxMatrix["periodNIntake"] <- cellNFluxMatrix["periodNIntake"] + periodNIntake;
		myPlot.cumulDepositedOM <- myPlot.cumulDepositedOM + sum(myPlot.depositedOMMap.values);
		myPlot.depositedOMMap <- [];
		lastNitrogenUpdateDate <- time;

		// Atmospheric fixation
 periodAtmoNFix <- atmoNFixationHaYear * yearToStep * hectareToCell; // kgN/step
 cellNFluxMatrix["periodAtmoNFix"] <-
		cellNFluxMatrix["periodAtmoNFix"] + periodAtmoNFix;

		// Emissions : Grillot (2018)
 float previousPeriodExcretionEmissions <- periodExcretionsNIntake * excretionsNEmissionFact;
		float previousPeriodUrineEmissions <- periodUrineNIntake * urineNEmissionFact;
		periodSoilNEmissions <- previousPeriodExcretionEmissions + previousPeriodUrineEmissions; // kgN/step
 cellNFluxMatrix["periodSoilNEmissions"] <-
		cellNFluxMatrix["periodSoilNEmissions"] + periodSoilNEmissions;

		// Stock update
 periodVarCellNstock <- periodNIntake - periodNUptake + periodAtmoNFix - periodSoilNEmissions;
		cellNstock <- cellNstock + periodVarCellNstock;
		cellNFluxMatrix["periodVarCellNstock"] <- cellNFluxMatrix["periodVarCellNstock"] + periodVarCellNstock;
	}

	////	Displays		////
 rgb borderColourValue;
	rgb rangelandColourValue <- LUColourList[3];
	rgb croplandColourValue <- LUColourList[5];

	// OMDeposit
 aspect OMDeposited {
		float OMIntakeColourValue <- 2 * (255 / (1 + exp(-myPlot.cumulDepositedOM / max(maxCropBiomassContent, maxRangelandBiomassContent) / (1 #week / step)))) - 255;
		float OMUptakeColourValue <- 2 * (255 / (1 + exp(-(myPlot.initialBiomassContent - myPlot.biomassContent) / maxCropBiomassContent / 2))) - 255;
		rgb OMColour <- rgb(255 - OMIntakeColourValue, 255 - OMIntakeColourValue - OMUptakeColourValue, 255 - OMUptakeColourValue);
		if myPlot.cellLUSimple = "Rangeland" {
			borderColourValue <- rangelandColourValue;
		} else if myPlot.cellLUSimple = "Cropland" {
			borderColourValue <- croplandColourValue;
		} else {
			borderColourValue <- #white;
		}

		draw rectangle(cellWidth, cellHeight) color: OMColour border: borderColourValue;
	}

	// Nitrogen
 aspect nitrogenStock {
		float nitrogenColourValue <- 255 * (1 - 1 / (1 + exp(initialSoilNStock * hectareToCell - cellNstock))); // Pretty sigmoid with infection at starting value.
 rgb
		nitrogenColor <- rgb(255, nitrogenColourValue, nitrogenColourValue);
		if myPlot.cellLUSimple = "Rangeland" {
			borderColourValue <- rangelandColourValue;
		} else if myPlot.cellLUSimple = "Cropland" {
			borderColourValue <- croplandColourValue;
		} else {
			borderColourValue <- rgb(102, 102, 102);
		}

		draw rectangle(cellWidth, cellHeight) color: nitrogenColor border: borderColourValue;
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

}

