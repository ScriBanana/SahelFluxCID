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
 map<string, float>
	croplandNFluxMatrix <- ["periodVarCellNstock"::0.0, "periodNUptake"::0.0, "periodNIntake"::0.0, "periodAtmoNFix"::0.0, "periodSoilNEmissions"::0.0];
	map<string, float> rangelandNFluxMatrix <- ["periodVarCellNstock"::0.0, "periodNUptake"::0.0, "periodNIntake"::0.0, "periodAtmoNFix"::0.0, "periodSoilNEmissions"::0.0];
	map<string, map> NFluxMap <- ["croplandCells"::croplandNFluxMatrix, "rangelandCells"::rangelandNFluxMatrix, "herds"::["varHerdsNStock"::0.0]];

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

		NFluxMap["croplandCells"] <- croplandNFluxMatrix;
		NFluxMap["rangelandCells"] <- rangelandNFluxMatrix;
		float
		varHerdsNStock <- float(NFluxMap["herds"]["varHerdsNStock"]) + croplandNFluxMatrix["periodNUptake"] + rangelandNFluxMatrix["periodNUptake"] - croplandNFluxMatrix["periodNIntake"] - rangelandNFluxMatrix["periodNIntake"];
		NFluxMap["herds"] <- ["varHerdsNStock"::varHerdsNStock]; //TODO ugly

	}

	// Compute global ENA indicators at the end of the simulation (Stark, 2016; Balandier, 2017, Latham, 2006)
 float TT;
	float TST;
	float ICR;
	list<float> NFluxList; // TODO clean this mess
 action computeENAIndicators {
		NFluxList <<+
		[croplandNFluxMatrix["periodNUptake"], croplandNFluxMatrix["periodNIntake"], rangelandNFluxMatrix["periodNUptake"], rangelandNFluxMatrix["periodNIntake"], croplandNFluxMatrix["periodAtmoNFix"], rangelandNFluxMatrix["periodAtmoNFix"], croplandNFluxMatrix["periodSoilNEmissions"], rangelandNFluxMatrix["periodSoilNEmissions"], croplandNFluxMatrix["periodVarCellNstock"], rangelandNFluxMatrix["periodVarCellNstock"], float(NFluxMap["herds"]["varHerdsNStock"])];

		// TT
 TT <- sum(croplandNFluxMatrix["periodNUptake"], croplandNFluxMatrix["periodNIntake"], rangelandNFluxMatrix["periodNUptake"], rangelandNFluxMatrix["periodNIntake"]);

		// TST
 float cropNVarIfNeg <- croplandNFluxMatrix["periodVarCellNstock"] < 0 ? croplandNFluxMatrix["periodVarCellNstock"] : 0.0;
		float rangeNVarIfNeg <- rangelandNFluxMatrix["periodVarCellNstock"] < 0 ? rangelandNFluxMatrix["periodVarCellNstock"] : 0.0;
		float herdsNVarIfNeg <- float(NFluxMap["herds"]["varHerdsNStock"]) < 0 ? float(NFluxMap["herds"]["varHerdsNStock"]) : 0.0;
		TST <- TT + croplandNFluxMatrix["periodAtmoNFix"] + rangelandNFluxMatrix["periodAtmoNFix"] - cropNVarIfNeg - rangeNVarIfNeg - herdsNVarIfNeg;

		// ICR
 ICR <- TT / TST;

		// Prompt
 write "		TT : " + TT / hectareToCell + " kgN/ha";
		write "		TST : " + TST / hectareToCell + " kgN/ha";
		write "		ICR : " + ICR;
	}

}

