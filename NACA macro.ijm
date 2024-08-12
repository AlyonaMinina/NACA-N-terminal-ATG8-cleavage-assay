//Clear the log window if it was open
	if (isOpen("Log")){
		selectWindow("Log");
		run("Close");
	}
	
//Print the greeting
	print(" ");
	print("Welcome to the NACA ImageJ macro (N-terminal ATG8 cleavage assay also known as the GFP-cleavage assay)!");
	print(" ");
	
// Ask the user what file format do they want to process
Dialog.create("Select the file format ");
Dialog.addChoice("Please select the image file format you want to process and hit ok to proceed to selecting the folder with images for analysis:", newArray(".scn", ".tif"));
Dialog.show();
File_format = Dialog.getChoice();


// Find the original directory and create a new one for quantification results
original_dir = getDirectory("Select a directory");
original_folder_name = File.getName(original_dir);
output_dir = original_dir + "Results" + File.separator;
File.makeDirectory(output_dir);

// Create the table for all assays results
Table.create("Assay Results");

 
// Get a list of all the files in the directory
file_list = getFileList(original_dir);

// Create a shorter list containing list of image files with only the selected format
if(File_format == ".scn"){
	image_list = newArray(0);
	for(s = 0; s < file_list.length; s++) {
	    if(endsWith(file_list[s], ".scn")) {
	        image_list = Array.concat(image_list, file_list[s]);
	    }
	}

} else{
	image_list = newArray(0);
	for(s = 0; s < file_list.length; s++) {
	    if(endsWith(file_list[s], ".tif")) {
	        image_list = Array.concat(image_list, file_list[s]);
	    }
	}
}


// Inform the user about how many images will be analyzed from the selected folder
print(image_list.length + " images were detected for analysis");
print("");

// Loop analysis through the list of image files
for (i = 0; i < image_list.length; i++){
    path = original_dir + image_list[i];
    run("Bio-Formats Windowless Importer", "open=path");    

    // Get the image file title and remove the extension from it    
    title = getTitle();
    a = lengthOf(title);
    b = a-4;
    short_name = substring(title, 0, b);
    selectWindow(title);

    // Print for the user what image is being processed
    print ("Processing image " + (i+1) + " out of " + image_list.length + ":");
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
		   if(File_format == ".scn"){
   			 run("Invert");
   	    	}
			
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
		waitForUser("Add all ROIs to ROI manager, then hit OK.\n\n1. For each lane select first the Tag-ATG8-fusion band and then the free Tag band.\n\n2. Add two ROIs selecting background for TAg-ATG8-fusion and free Tag\n\n3. NB! Keep ROI size the same for all selections!\n\n3. Hit ok, when done! "); 
	
	//Rename the ROIs and save them
			n = roiManager("count");
			x = 1;
			for ( r=0; r<n; r++ ) {
				    roiManager("Select", r);
				    odd = r % 2;		
					if (!odd) {
						roiManager("Rename", "Tag-ATG8 sample " + x);
						} else {
						roiManager("Rename", "Free Tag sample " + x-1);
						x=x-1;
						}
						x=x+1;
					}
			roiManager("Select", n-2);
			roiManager("Rename", "Background signal for Tag-ATG8 bands");
			roiManager("Select", n-1);
			roiManager("Rename", "Background signal for free Tag bands");
			roiManager("Show All with labels");
			roiManager("Save", output_dir + Assay_title +"_ROIs.zip");
			
			//measure and save IntDen
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
					
			//create a column for Integrated density without background
			 current_last_row = Table.size("Assay Results"); // Get the number of rows in the table
		     current_assay_rows = newArray(current_last_row); // Create an array to store rows belonging to the currently processed image    
		    // Iterate through the table to find rows belonging to the currently processed image
		    current_row_count = 0; // Initialize a counter for the current assay rows
		    for (row = 0; row < current_last_row; row++) {
		        Assay_subset = Table.getString("Assay name", row, "Assay Results"); 
		        if (Assay_subset == Assay_title) {
		            current_assay_rows[current_row_count] = row; // Assign the current row index to the current assay rows array
		            current_row_count++; // Increment the counter for the next row index
		        }
		    }
           Array.trim(current_assay_rows, current_row_count); // Trim the array to remove any unused elements

		   // Fetch background values for the currently processed images
		   Background_for_TagATG8 = Table.get("RawIntDen", current_last_row-2, "Assay Results");
		   Background_for_free_Tag = Table.get("RawIntDen", current_last_row-1, "Assay Results");
    
    // Process each row belonging to the currently processed image
    for (r = 0; r < current_row_count; r++) {
        row = current_assay_rows[r];
        Band_name = Table.getString("Band name", row, "Assay Results"); 
        if(indexOf(Band_name, "ATG8")>0) {			
	      Current_RawIntDen = Table.get("RawIntDen", row, "Assay Results");
	      IntDen_without_background = Current_RawIntDen - Background_for_TagATG8;
	 } else {			
	        Current_RawIntDen = Table.get("RawIntDen", row, "Assay Results");
	        IntDen_without_background = Current_RawIntDen - Background_for_free_Tag;
	 } 
        Table.set("RawIntDen_without_background", row, IntDen_without_background, "Assay Results");
    }

    // Create a column with sample numbers
    current_last_row = Table.size("Assay Results");
    for (row = 0; row < current_last_row; row++) {
        Band_name = Table.getString("Band name", row, "Assay Results"); 
        Sn_extraction = lastIndexOf(Band_name, "sample");
        if (Sn_extraction >= 0) {                   
            Sample_number = substring(Band_name, Sn_extraction);
            Table.set("Sample number", row, Sample_number, "Assay Results");
        }
    }
    Table.set("Sample number", current_last_row-3, "","Assay Results"); // Clean up the values for the two background rows
    Table.set("Sample number", current_last_row-2, "","Assay Results");
    Table.set("Sample number", current_last_row-1, "","Assay Results");
    
				
			//create a column with  sample numbers
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
			
		//create a column with  sample numbers calculation for the free Tag, expressed as % of all Tag detected in the sample
				current_last_row = Table.size("Assay Results");
				for (row = 1; row < current_last_row; row++) {
					Total_Tag = (Table.get("RawIntDen_without_background", row-1, "Assay Results")) + (Table.get("RawIntDen_without_background", row, "Assay Results"));
					Free_Tag = Table.get("RawIntDen_without_background", row, "Assay Results");
					Free_Tag_percent = 100*Free_Tag/Total_Tag;
					Table.set("Free Tag as % of total Tag detected in the sample", row, Free_Tag_percent, "Assay Results");
					row = row+1;
				 }
				 
		//clean up the table  from extra 0 and NaN values
		current_last_row = Table.size("Assay Results");
				for (row = 0; row < current_last_row; row++) {
					Table.set("Free Tag as % of total Tag detected in the sample", row, "", "Assay Results");
					row = row+1;
				}
				Table.set("Free Tag as % of total Tag detected in the sample", current_last_row-2, "", "Assay Results"); //clean out unnecessary 0
				Table.set("Free Tag as % of total Tag detected in the sample", current_last_row-1, "", "Assay Results");
		}		 
				
			//Save the quantification results into a .csv table file
			selectWindow("Results");
			run("Close");
			Table.save(output_dir + "NACA ImageJ macro results" + ".csv");
			run("Close All");
		

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
   print("All Done!");
   print("Your quantification results are saved in the folder " + output_dir);
   print(" "); 
   print(" ");
   print("Alyona Minina. 2024");	
