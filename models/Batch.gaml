/**
* Name: Batch
* Diverse batch experiements 
* Author: AS
* Tags: 
*/
model Batch

import "main.gaml"

global {
	csv_file giniFile <- csv_file("../includes/GiniVectors_N10000n2l84.csv");
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
		endDate <- 3.0 #days;
		biophysicalProcessesUpdateFreq <- 1.0 #days;
		outputsComputationFreq <- 1.0 #days;
		parcelDistrib <- "GiniVect";
		herdDistrib <- "GiniVect";
		vectGiniParcels <- giniMap.values[parcelGiniIndex] collect (each * meanParcelSize * 2);
		vectGiniHerds <- giniMap.values[herdGiniIndex] collect (each * meanHerdSize * 2);
	}

}

experiment batchICRGini autorun: true type: batch repeat: 4 until: stopSim {
	string outputFilePathAndName <- "../includes/SFCID_BatchOutput_h20p20r28l1m.csv";
	parameter "Gini index - parcel sizes" var: parcelGiniIndex min: 0 max: 1 step: 1;
	parameter "Gini index - herd sizes" var: herdGiniIndex min: 0 max: 1 step: 1;
	// Max has to be set up manually to giniMatrix.rows - 1
	init {
		write "Starting batch";
		save ["Run index", "Parcels gini index", "Herds gini index", "Mean TT", "Mean TST", "Mean ICR"] to: (outputFilePathAndName) type: "csv" header: false rewrite: true;
	}

	int runNb <- 1;

	reflex updateGiniVect {
	// Previous batch conclusion
		float meanTT <- mean(simulations collect each.TT);
		float meanTST <- mean(simulations collect each.TST);
		float meanICR <- mean(simulations collect each.ICR);
		write "End of run number : " + runNb;
		write "	Parcel gini index : " + giniMap.keys[parcelGiniIndex] + ", herd gini index : " + giniMap.keys[herdGiniIndex] + ", mean ICR : " + meanICR;
		save [runNb, giniMap.keys[parcelGiniIndex], giniMap.keys[herdGiniIndex], meanTT, meanTST, meanICR] to: (outputFilePathAndName) type: "csv" header: false rewrite: false;
		runNb <- runNb + 1;
	}

}