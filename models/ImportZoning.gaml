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

//	file zoningReduitAudouin15Diohine <- image_file("../includes/ZonageReduitDiohineAudouinEtAl2015.png");
	file zoningLRAudouin15Diohine <- image_file("../includes/ZonageReduitDiohineAudouinEtAl2015_LowRes.png");
	//	file testImg <- image_file("../includes/testImg.png");
	//	file testImg2 <- image_file("../includes/testImg2.png");
	file gridLayout <- zoningLRAudouin15Diohine;

	// Grid parameters and units
	geometry shape <- rectangle(4980 #m, 6140 #m); // suits for zoningLRAudouin15Diohine
	point villageLocation <- point(3294, 2993);
	// suits for zoningLRAudouin15Diohine
	float meanParcelSize <- 100.0 #m; // Satellite survey.
	float SDParcelSize <- 50.0 #m; // For normal distribution. Random value
	int gridHeight <- gridLayout.contents.rows;
	int gridWidth <- gridLayout.contents.columns;
	float cellHeight <- shape.height / gridHeight;
	float cellWidth <- shape.width / gridWidth;
	float hectareToCell <- cellWidth * cellHeight / 10000 #m2;

	// Landscape units definition (from source)
	list<string> LUList <- ["Dwellings", "Lowlands", "Ponds", "Wooded savannah", "Fallows", "Rainfed crops", "Gardens"];
	list<rgb> LUColourList <- [rgb(124, 130, 134), rgb(100, 217, 244), rgb(0, 114, 185), rgb(101, 198, 110), rgb(57, 208, 202), rgb(216, 232, 180), rgb(0, 187, 53)];
	//point villageLocation <- centroid(world);
}

