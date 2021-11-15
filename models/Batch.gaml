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
	list<float> giniList <- giniMatrix column_at 0;
	float parcelGini <- giniList[1]; // Avoid header, should be the smallest index despite sort in init
	list simuVectGiniSizes;

	init {
		giniList >- first(giniList);
		giniList <- giniList sort_by each;
		write "Launching batch";

		// Init first batch
		parcelDistrib <- "GiniVect";
		batchSim <- true;
		endDate <- 2.0 #week;
		simuVectGiniSizes <- giniMatrix row_at runNb; // Avoid header
		simuVectGiniSizes >- first(simuVectGiniSizes);
		vectGiniSizes <- simuVectGiniSizes;
	}

	parameter "Gini index - parcel sizes" var: parcelGini among: giniList;

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
		simuVectGiniSizes <- giniMatrix row_at runNb;
		simuVectGiniSizes >- first(simuVectGiniSizes);
		vectGiniSizes <- simuVectGiniSizes;
	}

}