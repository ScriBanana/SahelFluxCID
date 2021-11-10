/**
* Name: ExperimentRun
* In: SahelFlux
Single run of experiment. 
* Author: AS
* Tags: 
*/
model ExperimentRun

import "main.gaml"
grid secondaryGrid width: gridWidth height: gridHeight parallel: true;

experiment simulation type: gui {
	output {
		display mainDisplay type: java2D {
			grid landscape;
			species nightPaddock;
			species herd;
		}

		display nitrogenDisplay type: java2D refresh: every(visualUpdate) {
			grid secondaryGrid;
			species plotStockFlowMecanisms aspect: nitrogenStock;
		}

		display OMDepositDisplay type: java2D refresh: every(visualUpdate) {
			grid secondaryGrid;
			species plotStockFlowMecanisms aspect: OMDeposited;
		}

		//		display carbonDisplay type: java2D refresh: every(visualUpdate) {
		//			grid secondaryGrid border: #lightgrey;
		//			species stockFlowMecanisms aspect: carbonStock;
		//		}
		display plantBiomassChart refresh: every(visualUpdate) {
			chart "Total plant biomass evolution" type: series {
				data "Plant biomass" value: landscape sum_of (each.biomassContent);
			}

		}

		display nitrogenStocksChart refresh: every(visualUpdate) {
			chart "Soil nitrogen stock evolution" type: series {
				data "Total stock" value: plotStockFlowMecanisms sum_of (each.cellNstock);
			}

		}

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