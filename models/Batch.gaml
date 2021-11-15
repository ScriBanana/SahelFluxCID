/**
* Name: Batch
* Diverse batch experiements 
* Author: AS
* Tags: 
*/
model Batch

import "main.gaml"

global {
	csv_file giniFile <- csv_file("../includes/GiniVectorsN1000000n50m84.csv");
	matrix giniMatrix <- matrix(giniFile);
	map<float, list<float>> giniMap;
	int parcelGiniIndex <- 0; // Has to be inited
	int herdGiniIndex <- 0; // Has to be inited
	init {
	//	// Reform gini map
		loop matRow from: 0 to: giniMatrix.rows - 1 {
			list<float> sizeVect;
			loop matCol from: 1 to: giniMatrix.columns - 1 {
				sizeVect <+ float(giniMatrix[matCol, matRow]);
			}

			giniMap <+ giniMatrix[0, matRow]::sizeVect;
		}

		// Sim init
		batchSim <- true;
		endDate <- 2.0 #month;
		parcelDistrib <- "GiniVect";
		herdDistrib <- "GiniVect";
		vectGiniParcels <- giniMap.values[parcelGiniIndex];
		vectGiniHerds <- giniMap.values[herdGiniIndex];
	}

}

experiment batchICRGini autorun: true type: batch repeat: 28 until: stopSim parallel: true {
	parameter "Gini index - parcel sizes" var: parcelGiniIndex min: 0 max: 49 step: 1;
	parameter "Gini index - herd sizes" var: herdGiniIndex min: 0 max: 49 step: 1;
	// Max has to be set up manually to giniMatrix.rows - 1
	init {
		write "Starting batch";
	}

	int runNb <- 1;

	reflex updateGiniVect {
	// Previous batch conclusion
		float meanTT <- mean(simulations collect each.TT);
		float meanTST <- mean(simulations collect each.TST);
		float meanICR <- mean(simulations collect each.ICR);
		write "End of run number : " + runNb;
		write "	Parcel gini index : " + giniMap.keys[parcelGiniIndex] + ", herd gini index : " + giniMap.keys[herdGiniIndex] + ", mean ICR : " + meanICR;
		save [runNb, giniMap.keys[parcelGiniIndex], giniMap.keys[herdGiniIndex], meanTT, meanTST, meanICR] to: ("../includes/GiniVectorsN1000000n50m84.csv") type: "csv" header: true
		rewrite: false;
		runNb <- runNb + 1;
	}

}