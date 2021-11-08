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
	float propLabileCFixed <- 0.005; //TODO A PARAM ! selon LU?
	float propLabileCMineralised <- 0.05; //TODO A PARAM
	float propStableCMineralised <- 0.001; //TODO A PARAM !!SP!!

}

species stockFlowMecanisms parallel: true { // Likely more efficient than with a 'reflex when: !nonGrazable' in the grid.
	landscape myPlot;
	float soilNitrogenContent;
	float plantNitrogenContent;

	// 2 compartments carbon kinetic (based on ICBM; Andrén and Kätterer, 1997)
	float soilCInput <- 0.1; //TODO A PARAM
	float labileCStock <- 2.0; //TODOA PARAM
	float stableCStock <- 5.0; //TODO A PARAM
	float totalCStock <- labileCStock + stableCStock;

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
	aspect nitrogenStock {
	}

}

//grid secondaryGrid width: gridWidth height: gridHeight parallel: true;
