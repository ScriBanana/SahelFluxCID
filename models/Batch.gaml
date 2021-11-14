/**
* Name: Batch
* Diverse batch experiements 
* Author: AS
* Tags: 
*/
model Batch

import "main.gaml"
experiment batchICRGini autorun: false type: batch repeat: 10 until: stopSim {
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
		write simuVectGiniSizes;
	}

	parameter "Gini index - parcel sizes" var: parcelGini among: giniList;

	reflex updateGiniVect {
		runNb <- runNb + 1;
		write "Run number : " + runNb;
		simuVectGiniSizes <- giniMatrix row_at runNb;
		simuVectGiniSizes >- first(simuVectGiniSizes);
		vectGiniSizes <- simuVectGiniSizes;
	}

}