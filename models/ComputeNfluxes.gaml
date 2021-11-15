/**
* Name: ComputeNfluxes
* In: SahelFlux
* Computes N fluxes and ENA indicators based at the global level.
* Author: AS
* Tags: 
*/
model ComputeNfluxes

import "main.gaml"

global {

// Compute nitrogen flux in a global matrix
	map<string, float> croplandNFluxMatrix <- ["periodVarCellNstock"::0.0, "periodNUptake"::0.0, "periodNIntake"::0.0, "periodAtmoNFix"::0.0, "periodSoilNEmissions"::0.0];
	map<string, float> rangelandNFluxMatrix <- ["periodVarCellNstock"::0.0, "periodNUptake"::0.0, "periodNIntake"::0.0, "periodAtmoNFix"::0.0, "periodSoilNEmissions"::0.0];
	map<string, map> NFluxMatrix <- ["croplandCells"::croplandNFluxMatrix, "rangelandCells"::rangelandNFluxMatrix, "herds"::["varHerdsNStock"::0.0]];

	reflex updateNFluxMat when: every(outputsComputationFreq) {
		ask plotStockFlowMecanisms {
			loop fluxKey over: self.cellNFluxMatrix.keys {
				if self.myPlot.cellLUSimple = "Rangeland" {
					rangelandNFluxMatrix[fluxKey] <- rangelandNFluxMatrix[fluxKey] + self.cellNFluxMatrix[fluxKey];
				} else if self.myPlot.cellLUSimple = "Cropland" {
					croplandNFluxMatrix[fluxKey] <- croplandNFluxMatrix[fluxKey] + self.cellNFluxMatrix[fluxKey];
				}

			}

		}

		NFluxMatrix["croplandCells"] <- croplandNFluxMatrix;
		NFluxMatrix["rangelandCells"] <- rangelandNFluxMatrix;
		float
		varHerdsNStock <- float(NFluxMatrix["herds"]["varHerdsNStock"]) + croplandNFluxMatrix["periodNUptake"] + rangelandNFluxMatrix["periodNUptake"] - croplandNFluxMatrix["periodNIntake"] - rangelandNFluxMatrix["periodNIntake"];
		NFluxMatrix["herds"] <- ["varHerdsNStock"::varHerdsNStock]; //TODO ugly

	}

	// Compute global ENA indicators at the end of the simulation (Stark, 2016; Balandier, 2017, Latham, 2006)
	float TT;
	float TST;
	float ICR;

	action computeENAIndicators {
		TT <- sum(croplandNFluxMatrix["periodNUptake"], croplandNFluxMatrix["periodNIntake"], rangelandNFluxMatrix["periodNUptake"], rangelandNFluxMatrix["periodNIntake"]);
		TST <-
		TT + croplandNFluxMatrix["periodVarCellNstock"] + croplandNFluxMatrix["periodAtmoNFix"] + rangelandNFluxMatrix["periodVarCellNstock"] + rangelandNFluxMatrix["periodAtmoNFix"] + float(NFluxMatrix["herds"]["varHerdsNStock"]);
		ICR <- TT / TST;
		write "		TT : " + TT / hectareToCell + " kgN/ha/length of sim";
		write "		TST : " + TST / hectareToCell + " kgN/ha/length of sim";
		write "		ICR : " + ICR;
	}

}

