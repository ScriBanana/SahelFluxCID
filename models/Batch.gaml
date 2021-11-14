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
	list<float> giniList <- matrix(giniMatrix) column_at 0;
	list simuVectGiniSizes <- giniMatrix row_at runNb;
	float parcelGini <- giniList[1];

	init {
		giniList >- first(giniList);
		simuVectGiniSizes >- first(simuVectGiniSizes);
		vectGiniSizes <- simuVectGiniSizes;
		parcelDistrib <- "GiniVect";
		write "Launching batch";
		batchSim <- true;
		endDate <- 2.0 #week;
	}

	parameter "Gini index - parcel sizes" var: parcelGini among: giniList;

	reflex updateGiniVect {
		float meanICR <- mean(simulations collect each.ICR);
		write "End of run number : " + runNb;
		write "	Gini index : " + parcelGini + ", mean ICR : " + meanICR;
		save [runNb, parcelGini, meanICR] to: ("../includes/OutputsExploParcels.csv") type: "csv" header: true rewrite: false;
		runNb <- runNb + 1;

		// Initialize size vector
		simuVectGiniSizes <- giniMatrix row_at runNb;
		simuVectGiniSizes >- first(simuVectGiniSizes);
		vectGiniSizes <- simuVectGiniSizes;

		// Set simulation parameters
		batchSim <- true;
		endDate <- 2.0 #week;
	}

}