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

}

species plotStockFlowMecanisms parallel: true { // Likely more efficient than with a 'reflex when: !nonGrazable' in the grid.
	landscape myPlot;

	// Nitrogen
	float previousPeriodBiomass <- myPlot.biomassContent;

	reflex updateNitrogenFlows when: every(nitrogenFlowsUpdateFreq) {
	// Uptake
		float lastPeriodUptake <- myPlot.biomassContent - previousPeriodBiomass;

		// Excretions
		float lastPeriodIntake <- myPlot.depositedOMMap at 2.0;

		// Atmospheric fixation

		// Emissions
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
