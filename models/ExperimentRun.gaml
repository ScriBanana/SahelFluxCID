/**
* Name: ExperimentRun
* In: SahelFlux
Single run of experiment. 
* Author: AS
* Tags: 
*/
model ExperimentRun

import "main.gaml"
experiment simulation type: gui {
	parameter "Grid layout" var: gridLayout among: [testImg2, testImg, zoningReduitAudouin15Diohine]; //, zoningAudouin15Barry, zoningAudouin15Diohine]; // Marche malgré l'exception.
	output {
		display mainDisplay type: java2D {
			grid landscape;
			species nightPaddock;
			species herd;
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