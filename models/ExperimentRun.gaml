/**
* Name: ExperimentRun
* In: SahelFlux
Single run of experiment. 
* Author: AS
* Tags: 
*/
model ExperimentRun

import "main.gaml"
grid secondaryGrid width: gridWidth height: gridHeight parallel: true {

	init {
		color <- rgb(102, 102, 102);
	}

}

experiment simulation type: gui {
	output {
		layout horizontal([vertical([0::66, 2::33])::5, vertical([horizontal([1::5, 3::5])::33, 4::33, 4::33])::5]) navigator: false tabs: false toolbars: true;
		display mainDisplay type: java2D {
			grid landscape;
			species nightPaddock;
			species herd;
		}

		display OMDepositDisplay type: java2D refresh: every(visualUpdate) {
			grid secondaryGrid;
			species plotStockFlowMecanisms aspect: OMDeposited;
		}

		display plantBiomassChart refresh: every(visualUpdate) {
			chart "Plant biomass evolution" type: series {
				data "Plant biomass" value: landscape where !each.nonGrazable sum_of (each.biomassContent);
				data "Rangeland plant biomass" value: (landscape where (each.cellLUSimple = "Rangeland")) sum_of (each.biomassContent);
				data "Cropland plant biomass" value: (landscape where (each.cellLUSimple = "Cropland")) sum_of (each.biomassContent);
			}

		}

		display nitrogenDisplay type: java2D refresh: every(visualUpdate) {
			grid secondaryGrid;
			species plotStockFlowMecanisms aspect: nitrogenStock;
		}

		display nitrogenStocksChart refresh: every(visualUpdate) {
			chart "Soil nitrogen stock evolution" type: series {
				data "Total stock" value: plotStockFlowMecanisms sum_of (each.cellNstock);
				data "Rangeland stock" value: (plotStockFlowMecanisms where (each.myPlot.cellLUSimple = "Rangeland")) sum_of (each.cellNstock);
				data "Cropland stock" value: (plotStockFlowMecanisms where (each.myPlot.cellLUSimple = "Cropland")) sum_of (each.cellNstock);
			}

		}
		//		display carbonDisplay type: java2D refresh: every(visualUpdate) {
		//			grid secondaryGrid border: #lightgrey;
		//			species stockFlowMecanisms aspect: carbonStock;
		//		}

		//		display carbonStocksChart refresh: every(visualUpdate) {
		//			chart "Soil organic carbon evolution" type: series {
		//				data "Total stock" value: stockFlowMecanisms sum_of (each.totalCStock);
		//				data "Labile stock" value: stockFlowMecanisms sum_of (each.labileCStock);
		//				data "Stable stock" value: stockFlowMecanisms sum_of (each.stableCStock);
		//			}
		//
		//		}

	}

}