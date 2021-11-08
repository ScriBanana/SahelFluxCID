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
	float vegetalBiomassNContent <- 0.5; // TODO sourcer (Coly un peu lackluster) et faire varier selon LU

}

species plotStockFlowMecanisms parallel: true { // Likely more efficient than with a 'reflex when: !nonGrazable' in the grid.
	landscape myPlot;

	// Nitrogen
	float lastNitrogenUpdateDate <- time;
	float previousPeriodBiomass <- myPlot.biomassContent;

	reflex updateNitrogenFlows when: every(nitrogenFlowsUpdateFreq) {
	// Uptake
		float lastPeriodBMUptake <- myPlot.biomassContent - previousPeriodBiomass;
		previousPeriodBiomass <- myPlot.biomassContent;
		float lastPeriodNUptake <- lastPeriodBMUptake * vegetalBiomassNContent;

		// Excretions
		float lastPeriodOMIntake <- 0.0;
		loop OMDepositDate over: reverse(myPlot.depositedOMMap sort each) {
			if OMDepositDate <= lastNitrogenUpdateDate {
				break;
			}

			lastPeriodOMIntake <- lastPeriodOMIntake + myPlot.depositedOMMap at OMDepositDate;
		}

		float lastPeriodExcretionsNIntake;
		float lastPeriodUrineNIntake;
		float lastPeriodNIntake <- lastPeriodExcretionsNIntake + lastPeriodUrineNIntake;

		// Atmospheric fixation

		// Emissions : voir Myriam p.81
		lastNitrogenUpdateDate <- time;
	}

	aspect nitrogenStock {
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
	//		location <- myPlot.location;
	//		float carbonColourValue <- 255 * (1 - 1 / exp(10 - totalCStock)); // Pretty sigmoid; parameters a bit random.
	//		rgb carbonColor <- rgb(carbonColourValue, carbonColourValue, carbonColourValue);
	//		draw square(cellWidth) color: carbonColor;
	//	}

}

grid secondaryGrid width: gridWidth height: gridHeight parallel: true;
