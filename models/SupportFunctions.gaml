/**
* Name: SupportFunctions
* Various support functions. 
* Author: AS
* Tags: 
*/
model SupportFunctions

global {
// Compares a colour (rgb) to those of a list of colours and returns the index in the list of the closest colour (euclidian distance)
	rgb eucliClosestColour (rgb colourToCompare, list<rgb> colourPalette) {
		rgb closestColour;
		float shortestDist <- 3 ^ (1 / 2) * 255.0;
		loop refColour over: colourPalette {
			float rgbEucliDist <- ((refColour.red - colourToCompare.red) ^ 2 + (refColour.green - colourToCompare.green) ^ 2 + (refColour.blue - colourToCompare.blue) ^ 2) ^ (1 / 2);
			if rgbEucliDist < shortestDist {
				shortestDist <- rgbEucliDist;
				closestColour <- refColour;
			}

		}

		return closestColour;
	}

}
