/**
* Name: Batch
* Diverse batch experiements 
* Author: AS
* Tags: 
*/
model Batch

import "main.gaml"

global {
	csv_file giniFile <- csv_file("../includes/GiniVectors_N10000000n5l84.csv");
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
		biophysicalProcessesUpdateFreq <- 1.0 #days;
		outputsComputationFreq <- 1.0 #week;
		parcelDistrib <- "GiniVect";
		herdDistrib <- "GiniVect";
		vectGiniParcels <- giniMap.values[parcelGiniIndex] collect (each * meanParcelSize * 2);
		vectGiniHerds <- giniMap.values[herdGiniIndex] collect (each * meanHerdSize * 2);
	}

}

experiment batchICRGini autorun: true type: batch repeat: 52 until: stopSim {
	string outputFilePathAndName <- "../outputs/SFCID_BatchOutput_h" + giniMatrix.rows + "p" + giniMatrix.rows + "r52l2M.csv";
	parameter "Gini index - parcel sizes" var: parcelGiniIndex min: 0 max: 4 step: 1;
	parameter "Gini index - herd sizes" var: herdGiniIndex min: 0 max: 4 step: 1;
	// Max has to be set up manually to giniMatrix.rows - 1
 init {
		write "Starting batch";
		save ["Run index", "GiniP input", "GiniH input", "Mean TT", "SD TT", "Mean TST", "SD TST", "Mean ICR", "SD ICR", "Flux Matrix"] to: (outputFilePathAndName) type: "csv" header:
		false rewrite: true;
	}

	int runNb <- 1;

	reflex updateGiniVect {
	// Previous batch conclusion
 write "End of run number : " + runNb;

		// Control on Gini indexes
 list<float> simGiniPList <- simulations collect each.GiniP;
		list<float> simGiniHList <- simulations collect each.GiniH;

		// List of mean of fluxes (inelegant af)
 list<list<float>> simNFluxLists <- simulations collect each.NFluxList;
		list<float> listMeanSimNFlux;
		loop indFlux from: 0 to: length(simNFluxLists[0]) - 1 {
			list<float> fluxVal;
			loop indSim from: 0 to: length(simNFluxLists) - 1 {
				fluxVal <+ simNFluxLists[indSim][indFlux];
			}

			listMeanSimNFlux <+ mean(fluxVal);
		}

		float meanTT <- mean(simulations collect each.TT);
		float meanTST <- mean(simulations collect each.TST);
		float meanICR <- mean(simulations collect each.ICR);
		float SDTT <- standard_deviation(simulations collect each.TT);
		float SDTST <- standard_deviation(simulations collect each.TST);
		float SDICR <- standard_deviation(simulations collect each.ICR);

		// Prompt
 write "	Parcel gini index : " + giniMap.keys[parcelGiniIndex] + ", herd gini index : " + giniMap.keys[herdGiniIndex] + ", mean ICR : " + meanICR;
		write "	Mean flux vector : " + listMeanSimNFlux;

		// Saves
		save [runNb, giniMap.keys[parcelGiniIndex], giniMap.keys[herdGiniIndex], meanTT, SDTT, meanTST, SDTST, meanICR, SDICR, listMeanSimNFlux] to: (outputFilePathAndName) type: "csv"
		header: false rewrite: false;
		save [runNb, simNFluxLists] to: ("../outputs/SFCID_BatchOutput_h" + giniMatrix.rows + "p" + giniMatrix.rows + "r52l2M_NFluxLists.csv") type: "csv" header: false rewrite: false;
		save [runNb, simGiniPList] to: ("../outputs/SFCID_BatchOutput_h" + giniMatrix.rows + "p" + giniMatrix.rows + "r52l2M_simGiniPList.csv") type: "csv" header: false rewrite:
		false;
		save [runNb, simGiniHList] to: ("../outputs/SFCID_BatchOutput_h" + giniMatrix.rows + "p" + giniMatrix.rows + "r52l2M_simGiniHList.csv") type: "csv" header: false rewrite:
		false;
		runNb <- runNb + 1;
	}

}