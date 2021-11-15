/**
* Name: GenerGini
* In: SahelFlux
* Generates nbLists lists of lengthLists integers from 0 to maxValue with corresponding Gini indicators.
*  
* Author: AS
* Tags: 
*/
model GenerGini

global {
	int nbLists <- 1000000;
	int nbListsSaved <- 50;
	int lengthLists <- 84;
	float mean <- 20.0;
	float sd <- 2.0;
	float maxValue <- 200.0; // mean will be half
	map<float, list> outputMat;

	init {
		write "Generating";
		loop times: nbLists {
			list<float> vect <- [];
			loop times: lengthLists {
			//	vect <+ gauss(mean, sd);
				vect <+ rnd(maxValue);
			}

			outputMat <+ gini(vect)::vect;
		}

		write "Saving";
		//write "Gini indexes : " + outputMat.keys;
		write "Nb lists = " + nbLists + ", lists length = " + lengthLists;
		write "Gini indexes - Min : " + min(outputMat.keys) + ", mean : " + mean(outputMat.keys) + ", median : " + median(outputMat.keys) + ", max : " + max(outputMat.keys);

		// Save nbLinesSaved lines
		save ["Gini index", "Value vector"] to: ("../includes/GiniVectorsN" + nbLists + "n" + nbListsSaved + "m" + lengthLists + ".csv") type: "csv" header: false rewrite: true;
		list sortedMatKeys <- outputMat.keys sort_by (each);
		list sortedMatKeysInvert <- outputMat.keys sort_by (-each);
		loop i from: 0 to: nbListsSaved / 2 - 1 {
			float gini <- sortedMatKeys[int(i * nbLists / nbListsSaved)];
			float giniInv <- sortedMatKeysInvert[int(i * nbLists / nbListsSaved)];
			list valueVect <- outputMat[gini];
			list valueVectinv <- outputMat[giniInv];
			list<float> vectToSave <- [gini];
			list<float> vectToSaveInv <- [giniInv];
			loop value over: valueVect {
				vectToSave <+ float(value);
			}

			loop valueInv over: valueVectinv {
				vectToSaveInv <+ float(valueInv);
			}

			save vectToSave to: ("../includes/GiniVectorsN" + nbLists + "n" + nbListsSaved + "m" + lengthLists + ".csv") type: "csv" header: false rewrite: false;
			save vectToSaveInv to: ("../includes/GiniVectorsN" + nbLists + "n" + nbListsSaved + "m" + lengthLists + ".csv") type: "csv" header: false rewrite: false;
		}

		write "Done";
	}

}

experiment run type: gui {
}