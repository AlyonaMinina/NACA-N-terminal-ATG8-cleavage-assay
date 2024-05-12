//Clear the log window if it was open
	if (isOpen("Log")){
		selectWindow("Log");
		run("Close");
	}
	
//Print the greeting
	print(" ");
	print("Welcome to the GFP-cleavage assay macro!");
	print(" ");
	print("Please note this macro will process .tif images");
	print(" ");
	print("Please select the folder with images for analysis");
	print(" ");

//Find the original directory and create a new one for quantification results
	original_dir = getDirectory("Select a directory");
	original_folder_name = File.getName(original_dir);
	output_dir = original_dir +"Densitometry results" + File.separator;
	File.makeDirectory(output_dir);

//Create the table for all assays results
	Table.create("Assay Results");
	

// Get a list of all the files in the directory
	file_list = getFileList(original_dir);


//Create a shorter list contiaiing .tif files only
	WB_list = newArray(0);
	for(s = 0; s < file_list.length; s++) {
		if(endsWith(file_list[s], ".tif")) { 
			WB_list = Array.concat(WB_list, file_list[s]);
		}
	}
	
//inform the user about how many images will be analyzed from the selected folder
	print(WB_list.length + " images were detected for analysis");
	print("");

//Loop analysis through the list of WB_list
	for (i = 0; i < WB_list.length; i++){
		path = original_dir + WB_list[i];
		run("Bio-Formats Windowless Importer",  "open=path");    
	
	//Get the image file title and remove the extension from it    
		title = getTitle();
		a = lengthOf(title);
		b = a-4;
		short_name = substring(title, 0, b);
		selectWindow(title);
				
	//Print for the user what image is being processed
		print ("Processing image " + i+1 + " out of " + WB_list.length + ":");
		print(title);
		print("");
		
	//Ask user how to call this quantification
	Assay_title = "AZD";
	Dialog.create("Please enter the name of your quantification");
	Dialog.addString("Assay title", Assay_title);
	Dialog.show();
	Assay_title = Dialog.getString();
	Assay_title = Assay_title + " image " + short_name;
	

	//Place the ROIs for each band
		run("ROI Manager...");
		roiManager("reset");
			
	//Wait for the user to crop/rotate the image and save the result
		waitForUser("Please rotate the image to place bands horizontally\n\nUse 0 degrees if no rotation is needed.\n\nHit ok to proceed to rotation");
		run("Rotate... ");
		setTool("rectangle");
		waitForUser("Please crop the image if needed:\n\n 1.Draw a selection (the Rectangle tool is already activate)\n\n 2.Use Ctrl+Shit+X\n\n 3. Hit ok, when done!");
		saveAs("Tiff", output_dir + Assay_title + ".tif");
	
	//Make sure ROI Manager is clean of any additional ROIs
		roiManager("reset");
		setTool("rectangle");
		roiManager("Show All with labels");
		
	//Wait for the user to adjust the ROIs size and position
		waitForUser("Add all ROIs to ROI manager, then hit OK.\n\n1. For each lane select first the GFP-fusion band and then the free GFP band.\n\n2. Add two ROIs selecting background for GFP-fusion and free GFP\n\n3. NB! Keep ROI size the same for all selections!\n\n3. Hit ok, when done! "); 
	
	//Rename the ROIs and save them
			
			n = roiManager("count");
			x = 1;
			for ( r=0; r<n; r++ ) {
				    roiManager("Select", r);
				    odd = r % 2;		
					if (!odd) {
						roiManager("Rename", "GFP-ATG8 sample " + x);
						} else {
						roiManager("Rename", "GFP sample " + x-1);
						x=x-1;
						}
						x=x+1;
					}
			roiManager("Select", n-2);
			roiManager("Rename", "Background signal for GFP-ATG8 bands");
			roiManager("Select", n-1);
			roiManager("Rename", "Background signal for free GFP bands");
			roiManager("Show All with labels");
			roiManager("Save", output_dir + Assay_title +"_ROIs.zip");
			
			//measure and save integrated density for each ROI
			run("Invert");
			for ( r=0; r<n; r++ ) {
					run("Clear Results");
				    roiManager("Select", r);
				    ROI_Name = Roi.getName();
				    run("Set Measurements...", "area integrated redirect=None decimal=3");
					roiManager("Measure");
					area = getResult("Area", 0);
					IntDen = getResult("IntDen", 0);
					RawIntDen = getResult("RawIntDen", 0);
					current_last_row = Table.size("Assay Results");
					Table.set("Assay name", current_last_row, Assay_title, "Assay Results");
					Table.set("Band name", current_last_row, ROI_Name, "Assay Results");
					Table.set("Band area", current_last_row, area, "Assay Results");
					Table.set("IntDen", current_last_row, IntDen, "Assay Results");
					Table.set("RawIntDen", current_last_row, RawIntDen, "Assay Results");
					}
					
			//create a column for Raw Integrated Density without background
				current_last_row = Table.size("Assay Results");
				Background_for_GFPATG8 = Table.get("RawIntDen", current_last_row-2, "Assay Results");
				Background_for_free_GFP = Table.get("RawIntDen", current_last_row-1, "Assay Results");
								
				for (row = 0; row < current_last_row; row++) {
					Band_name =Table.getString("Band name", row, "Assay Results"); 
					if(indexOf(Band_name, "ATG8")>0) {			
		   			     Current_RawIntDen = Table.get("RawIntDen", row, "Assay Results");
						 IntDen_without_background = Current_RawIntDen - Background_for_GFPATG8;
						 } else {			
		   			     Current_RawIntDen = Table.get("RawIntDen", row, "Assay Results");
						 IntDen_without_background = Current_RawIntDen - Background_for_free_GFP;
						 	} 
						 
						 Table.set("RawIntDen_without_background", row, IntDen_without_background, "Assay Results");
				}
				
			//create a column with sample numbers = lane numbers
				current_last_row = Table.size("Assay Results");
				for (row = 0; row < current_last_row; row++) {
					Band_name =Table.getString("Band name", row, "Assay Results"); 
					Sn_extraction = lastIndexOf(Band_name, "sample");
					 if (Sn_extraction >= 0) {					
						Sample_number = substring(Band_name, Sn_extraction);
					Table.set("Sample number", row, Sample_number, "Assay Results");
				 }
			}
			Table.set("Sample number", current_last_row-2, "","Assay Results"); //clean up the values for the two background rows
			Table.set("Sample number", current_last_row-1, "","Assay Results");
			
		//create a column with calculation for the free GFP, expressed as % of all gFP detected in the sample
				current_last_row = Table.size("Assay Results");
				for (row = 1; row < current_last_row; row++) {
					Total_GFP = (Table.get("RawIntDen_without_background", row-1, "Assay Results")) + (Table.get("RawIntDen_without_background", row, "Assay Results"));
					Free_GFP = Table.get("RawIntDen_without_background", row, "Assay Results");
					Free_GFP_percent = 100*Free_GFP/Total_GFP;
					Table.set("Free GFP as % of total GFP detected in the sample", row, Free_GFP_percent, "Assay Results");
					row = row+1;
				 }
				 
		//clean up the table from non-relevant 0 and NaN values
		current_last_row = Table.size("Assay Results");
				for (row = 0; row < current_last_row; row++) {
					Table.set("Free GFP as % of total GFP detected in the sample", row, "", "Assay Results");
					row = row+1;
				}
		Table.set("Free GFP as % of total GFP detected in the sample", current_last_row-1, "", "Assay Results");
				 
				
			//Save the quantification results into a .csv table file
			selectWindow("Results");
			run("Close");
			Table.save(output_dir + "Results " + Assay_title+ ".csv");
			run("Close All");
		}

//A feeble attempt to close those pesky ImageJ windows		
	run("Close All");
	if (isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");
	}
	
	if (isOpen("Assay Results")){
		selectWindow("Assay Results");
		run("Close");
	}
	
	
 
//Print the final message
   print(" ");
   print("Done!");
   print(" ");
   print("Your quantification results are saved in the folder\n\n " + output_dir);
   print(" ");
   print("When describing your analysis, please reference the repository\n\nhttps://github.com/AlyonaMinina/GFP-cleavage-assay\n\n Alyona Minina. 2024");	
   selectWindow("Log");
   saveAs("Text",  output_dir + "Analysis summary.txt");
