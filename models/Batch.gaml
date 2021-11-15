/**
* Name: Batch
* Diverse batch experiements 
* Author: AS
* Tags: 
*/
model Batch

import "main.gaml"
experiment batchICRGini autorun: false type: batch repeat: 4 until: stopSim {
	int runNb <- 1;
	csv_file giniFile <- csv_file("../includes/GiniVectorsN1000n100m84.csv");
	matrix giniMatrix <- matrix(giniFile);
	map<float, list> giniMap;
	float parcelGini <- (giniMatrix column_at 0)[1]; // Avoid header
	init {
	// Reform gini map
		loop matRow from: 0 to: giniMatrix.rows - 1 {
			list<float> sizeVect;
			loop matCol from: 1 to: giniMatrix.columns - 1 {
				sizeVect <+ float(giniMatrix[matCol, matRow]);
			}

			giniMap <+ giniMatrix[0, matRow]::sizeVect;
		}

		write "Launching batch";

		// Init first batch
		parcelDistrib <- "GiniVect";
		batchSim <- true;
		endDate <- 2.0 #week;
		vectGiniSizes <- giniMap[parcelGini];
	}

	parameter "Gini index - parcel sizes" var: parcelGini among: giniMap.keys sort_by each;

	reflex updateGiniVect {
	// Previous batch conclusion
		float meanICR <- mean(simulations collect each.ICR);
		write "End of run number : " + runNb;
		write "	Gini index : " + parcelGini + ", mean ICR : " + meanICR;
		save [runNb, parcelGini, meanICR] to: ("../includes/OutputsExploParcels.csv") type: "csv" header: true rewrite: false;

		// New batch init
		runNb <- runNb + 1;
		write "Init batch " + runNb + ", gini index : " + parcelGini;
		parcelDistrib <- "GiniVect";
		batchSim <- true;
		endDate <- 2.0 #week;
		vectGiniSizes <- giniMap[parcelGini];
	}

}