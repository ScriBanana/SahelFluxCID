/**
* Name: ImportZoning
* Imports rasters from Audoin's papers and classifies pixels with their land use.
* Author: AS
* Tags: 
*/
model ImportZoning

import "main.gaml"
import "SupportFunctions.gaml"

global {
// Zoning imports (source : Audouin, E., Vayssières, J., Odru, M., Masse, D., Dorégo, S., Delaunay, V., Lecomte, P., 2015. Réintroduire l’élevage pour accroître la durabilité des terroirs villageois d’Afrique de l’Ouest. Les sociétés rurales face aux changements environnementaux en Afrique de l’Ouest. IRD, Marseille, France 403–427.)
//	file zoningAudouin15Barry <- image_file("../includes/ZonageBarrySineAudouinEtAl2015.png");
//	file zoningAudouin15Diohine <- image_file("../includes/ZonageDiohineAudouinEtAl2015.png");
	file zoningReduitAudouin15Diohine <- image_file("../includes/ZonageReduitDiohineAudouinEtAl2015.png");
	file testImg <- image_file("../includes/testImg.png");
	file testImg2 <- image_file("../includes/testImg2.png");
	file gridLayout <- testImg2;

	// Grid parameters
	int gridHeight <- gridLayout.contents.rows;
	int gridWidth <- gridLayout.contents.columns;

	// Landscape units definition (from source)
	list<string> LUList <- ["Dwellings", "Lowlands", "Ponds", "Wooded savannah", "Fallows", "Rainfed crops", "Gardens"];
	list<rgb> LUColourList <- [rgb(124, 130, 134), rgb(44, 217, 244), rgb(0, 114, 185), rgb(101, 198, 110), rgb(57, 208, 202), rgb(216, 232, 180), rgb(0, 187, 53)];
}

