/**
* Name: Batch
* Diverse batch experiements 
* Author: AS
* Tags: 
*/
model Batch

import "main.gaml"

global {
	csv_file giniFile <- csv_file("../includes/GiniVectorsN1000n100m84.csv");
	matrix giniMatrix <- matrix(giniFile);
	map<float, list<float>> giniMap;
	int parcelGiniIndex;

	init {
	// Reform gini map
		loop matRow from: 0 to: giniMatrix.rows - 1 {
			list<float> sizeVect;
			loop matCol from: 1 to: giniMatrix.columns - 1 {
				sizeVect <+ float(giniMatrix[matCol, matRow]);
			}

			giniMap <+ giniMatrix[0, matRow]::sizeVect;
		}

		// Sim init
		parcelDistrib <- "GiniVect";
		batchSim <- true;
		endDate <- 2.0 #week;
		vectGiniSizes <- giniMap.values[parcelGiniIndex];
	}

}

experiment batchICRGini autorun: false type: batch repeat: 4 until: stopSim {
	int runNb <- 1;
	parameter "Gini index - parcel sizes" var: parcelGiniIndex init: 0 min: 0 max: 99; // Has to be set up manually to giniMatrix.rows - 1
	init {
		write "Starting batch";
	}

	reflex updateGiniVect {
	// Previous batch conclusion
		float meanICR <- mean(simulations collect each.ICR);
		write "End of run number : " + runNb;
		write "	Gini index : " + giniMap.keys[parcelGiniIndex] + ", mean ICR : " + meanICR;
		save [runNb, giniMap.keys[parcelGiniIndex], meanICR] to: ("../includes/OutputsExploParcels.csv") type: "csv" header: true rewrite: false;
	}

}