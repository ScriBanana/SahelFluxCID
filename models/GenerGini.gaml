/**
* Name: GenerGini
* In: SahelFlux
* Generates lists of float with various corresponding Gini indicators. 
*  
* Author: AS
* Tags: 
*/
model GenerGini

global {
	int nbLists <- 1000000;
	int lengthLists <- 84;
	float mean <- 20.0;
	float sd <- 2.0;
	float max <- 30.0;
	map<float, list> outputMat;

	init {
		loop times: nbLists {
			list<float> vect <- [];
			loop times: lengthLists {
			//	vect <+ gauss(mean, sd);
 vect <+ rnd(max);
			}

			outputMat <+ gini(vect)::vect;
		}

		//write "Gini indexes : " + outputMat.keys;
 write "Nb lists = " + nbLists + ", lists length = " + lengthLists;
		write "Gini indexes - Min : " + min(outputMat.keys) + ", mean : " + mean(outputMat.keys) + ", max : " + max(outputMat.keys);
	}

}

experiment sim type: gui {
}