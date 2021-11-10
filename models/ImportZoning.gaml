/**
* Name: ImportZoning
* In: SahelFlux
* Imports rasters from Audoin's papers and classifies pixels with their land use (Audouin et al. 2015).
* Author: AS
* Tags: 
*/
model ImportZoning

import "SupportFunctions.gaml"

global {
//	file zoningAudouin15Barry <- image_file("../includes/ZonageBarrySineAudouinEtAl2015.png");
//	file zoningAudouin15Diohine <- image_file("../includes/ZonageDiohineAudouinEtAl2015.png");
	file zoningReduitAudouin15Diohine <- image_file("../includes/ZonageReduitDiohineAudouinEtAl2015.png");
	file testImg <- image_file("../includes/testImg.png");
	file testImg2 <- image_file("../includes/testImg2.png");
	file gridLayout <- testImg2;

	// Grid parameters and units
	int gridHeight <- gridLayout.contents.rows;
	int gridWidth <- gridLayout.contents.columns;
	geometry shape <- rectangle(5150 #m, 5800 #m); // suits for zoningReduitAudouin15Diohine
	float cellHeight <- shape.height / gridHeight;
	float cellWidth <- shape.width / gridWidth;
	float hectareToCell <- cellWidth * cellHeight / 10000 #m2;
	float parcelSize <- 100.0 #m; // Satellite survey.

	// Landscape units definition (from source)
	list<string> LUList <- ["Dwellings", "Lowlands", "Ponds", "Wooded savannah", "Fallows", "Rainfed crops", "Gardens"];
	list<rgb> LUColourList <- [rgb(124, 130, 134), rgb(44, 217, 244), rgb(0, 114, 185), rgb(101, 198, 110), rgb(57, 208, 202), rgb(216, 232, 180), rgb(0, 187, 53)];
	//point villageLocation <- centroid(world);
	point villageLocation <- point(2961, 4205);
}

