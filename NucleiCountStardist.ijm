#@ File (label = "Input directory", style = "directory") inputdir
#@ File (label = "Output directory", style = "directory") outputdir
#@ Integer (label = "Minimum cell size", style = "spinner", default = 150) minsize

run("Fresh Start");
//setBatchMode(true);

// Find files
fileList0 = getFileList(inputdir);
n_files0 = lengthOf(fileList0);
print("Found " + n_files0 + " files");

// Filter out non-images
fileList = newArray();
for(i=0; i<lengthOf(fileList0); i++){
	this_file = fileList0[i];
	if(endsWith(this_file, ".tif")){
		fileList = Array.concat(fileList,this_file);
	}
}
n_files = lengthOf(fileList);
print("Found " + n_files + " images");


// Initialize results table
Table.create("cell_counts");



// Process files
print("Starting image processing")
for (i = 0; i < fileList.length; i++) {
    // open file
    this_file = fileList[i];
    inputPath = inputdir + "/" + this_file;
    print("   Opening: " + this_file);
    open(inputPath);
    processImage(minsize);
    
    // Find out how many cells (BIOP)
    roiManager("reset");
    run("Label image to ROIs", "rm=[RoiManager[size=133, visible=true]]");
    n_cells = roiManager("count");
    print("   " + n_cells + " cells");
    Table.set("File", Table.size, this_file, "cell_counts");
    Table.set("n_cells", Table.size-1, n_cells, "cell_counts");
    Table.update;
        
    // Save image
	outpath = outputdir + "/" + replace(this_file, ".tif", "--masks.tif");
	saveAs("Tiff", outpath);
    close();
}

// Save table
Table.save(outputdir + "/results.csv", "cell_counts");

print("The end");


function processImage(size_min) { 

	// Segment nuclei using stardist
	img = getTitle();
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + img + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.6', 'nmsThresh':'0.4', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	img1 = getTitle();
	close(img);
	selectWindow(img1);
	rename(img);
	
	// Exclude borders (MorpholibJ)
	run("8-bit");
	run("Remove Border Labels", "left right top bottom");
	img1 = getTitle();
	close(img);
	selectWindow(img1);
	rename(img);	
	
	// Exclude weird nuclei (MorpholibJ)
	run("Label Size Filtering", "operation=Greater_Than size=" + size_min);
	img1 = getTitle();
	close(img);
	selectWindow(img1);
	rename(img);
}


