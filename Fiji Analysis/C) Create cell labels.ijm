#@File(label="Select the image Directory", style="directory") imageDir
#@File(label="Select the particle segmentation Directory", style="directory") segmentationDir
#@File(label="Select the cell segmentation Directory", style="directory") cellSegmentationDir
#@Double(label="Pixel size in um", value="0.1035801") pixelSize
#@String (visibility=MESSAGE, value="<html><b>Particle Segmentation Parameters</b></html>", required=false) msg1
#@Integer(label="Particle Label value", value="1") ParticleLabelValue
#@Integer(label="Minimum Particle area [px]", value="2") minParticleArea
#@Boolean (label="Watershed Particule", value=false) doWatershed
#@String (visibility=MESSAGE, value="<html><b>Cell Segmentation Parameters</b></html>", required=false) msg2
#@Integer(label="Cell Label value", value="1") cellLabelValue
#@Integer(label="Minimum Cell area [px]", value="2000") minCellArea
#@Boolean (label="Watershed Cell Mask", value=false) doCellWatershed
#@Integer(label="ChloroplastChannel", value="3") chloroplastChannel
#@Integer(label="Filter Cell By Max intensity of chloroplast (0 no filtering)", value="100") maxIntensityChloroplast
#@String (visibility=MESSAGE, value="<html><b>Analyze Region Features</b></html>", required=false) msg3
#@Boolean (label="Area", value=false)                   doArea
#@Boolean (label="Perimeter", value=false)              doPerimeter
#@Boolean (label="Circularity", value=false)            doCircularity
#@Boolean (label="Euler Number", value=false)           doEuler_number
#@Boolean (label="Bounding Box", value=false)           doBounding_box
#@Boolean (label="Centroid", value=false)               doCentroid
#@Boolean (label="Equivalent Ellipse", value=false)     doEquivalent_ellipse
#@Boolean (label="Ellipse Elongation", value=false)     doEllipse_elong
#@Boolean (label="Convexity", value=false)              doConvexity
#@Boolean (label="Maximum Feret", value=false)          doMax_feret
#@Boolean (label="Oriented box", value=false)           doOriented_box
#@Boolean (label="Oriented box elongation", value=false)doOriented_box_elong
#@Boolean (label="Geodesic", value=false)               doGeodesic
#@Boolean (label="Tortuosity", value=false)             doTortuosity
#@Boolean (label="Maximum inscribed disc", value=false) doMax_inscribed_disc
#@Boolean (label="Average thickness", value=false)      doAverage_thickness
#@Boolean (label="Geodesic Elongation", value=false)    doGeodesic_elong


//TODO
//Per image, add another output file:
//Filename | Number of chloroplast | Number of lipid bodies (particle) | total cell area

//#@ Integer(label="Minimum Cell Area [px]", value="250") seg_minCellArea

//See https://imagej.net/Script_Parameters for a whole list of parameters

//2023/02/08
//
// Purpose:
//Perform a serie of measurement from label images saved as Ilastik segmentation mask
//
// Script steps:
//  For each image in the folder:
//    - detect the cell total area, remove tiny structure and measure the total area 
//    - detect the particle within the cell area, filter them by area and extract shape and intensity features

//Author: Benjamin Pavie - benjamin.pavie@vib.be

//Requirement:
//-Fiji/ImageJ
//-MorpholibJ (see https://imagej.net/MorphoLibJ)

setOption("ExpandableArrays", true);
//Build the command given the boolean selection

analysisRegionCommand = newArray();

//Check if the labels subfolder exist, otherwise create it
if (!File.exists(File.getParent(imageDir)+File.separator+"labels"))
  File.makeDirectory(File.getParent(imageDir)+File.separator+"labels");


if(doArea)
  analysisRegionCommand[analysisRegionCommand.length]="area";
if(doPerimeter)
  analysisRegionCommand[analysisRegionCommand.length]="perimeter";
if(doCircularity)
  analysisRegionCommand[analysisRegionCommand.length]="circularity";
if(doEuler_number)
  analysisRegionCommand[analysisRegionCommand.length]="euler_number";
if(doBounding_box)
  analysisRegionCommand[analysisRegionCommand.length]="bounding_box";
if(doCentroid)
  analysisRegionCommand[analysisRegionCommand.length]="centroid";
if(doEquivalent_ellipse)
  analysisRegionCommand[analysisRegionCommand.length]="equivalent_ellipse";
if(doEllipse_elong)
  analysisRegionCommand[analysisRegionCommand.length]="ellipse_elong.";
if(doConvexity)
  analysisRegionCommand[analysisRegionCommand.length]="convexity";
if(doMax_feret)
  analysisRegionCommand[analysisRegionCommand.length]="max._feret";
if(doOriented_box)
  analysisRegionCommand[analysisRegionCommand.length]="oriented_box";
if(doOriented_box_elong)
  analysisRegionCommand[analysisRegionCommand.length]="oriented_box_elong.";
if(doGeodesic)
  analysisRegionCommand[analysisRegionCommand.length]="geodesic";
if(doTortuosity)
  analysisRegionCommand[analysisRegionCommand.length]="tortuosity";
if(doMax_inscribed_disc)
  analysisRegionCommand[analysisRegionCommand.length]="max._inscribed_disc";
if(doAverage_thickness)
  analysisRegionCommand[analysisRegionCommand.length]="average_thickness";
if(doGeodesic_elong)
  analysisRegionCommand[analysisRegionCommand.length]="geodesic_elong";

analysisRegionCom="";
for(i=0;i<analysisRegionCommand.length; i++)
{
  if(i==0)
    analysisRegionCom=analysisRegionCommand[i];
  else
    analysisRegionCom=analysisRegionCom+" "+analysisRegionCommand[i];
}


//List all the files
list =getFilesList(imageDir, "tif");
list_segmentation =getFilesList(segmentationDir, "tiff");

///Save results file in dir1 with specified headings
resultTxtFile=imageDir+File.separator+"result.txt";
//Delete the previous result file
if(File.exists(resultTxtFile))
  File.delete(resultTxtFile);

columns="";

print("list.length:"+list.length);

//setBatchMode(true);
for (i=0; i<list.length; i++) 
{
    original_path = imageDir+File.separator+list[i];
    segmentation_path = segmentationDir+File.separator+list_segmentation[i];    
    cell_segmentation_path = cellSegmentationDir+File.separator+list_segmentation[i];  
    
    
    baseName=getBasename(list[i]);
    IJ.log("Processing file "+baseName); 
    IJ.log("  Raw file "+original_path); 
    IJ.log("  Segmentation file "+segmentation_path); 
       
    //open(segmentation_path);    
    run("Bio-Formats", "open=["+segmentation_path+"] " +"autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
    rename("segImage");
    segImageID= getImageID();
    //imageID=0;
    //selectImage(oriImageID);
    
    run("Bio-Formats", "open=["+original_path+"] " +"autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
    rename("raw");
    rawImageID= getImageID();
    
    setOption("ExpandableArrays", true);
    
  //open(segmentation_path);    
  print(cell_segmentation_path);
  run("Bio-Formats", "open=["+cell_segmentation_path+"] " +"autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
  rename("cellSegImage");
  cellMaskID= getImageID();
  setThreshold(cellLabelValue, cellLabelValue, "raw");
  run("Convert to Mask");  
  run("Analyze Particles...", "size="+minCellArea+"-Infinity pixel show=Masks in_situ");   
  
  selectImage(cellMaskID);   
  
  if(doCellWatershed)
    run("Watershed");
  
  run("Connected Components Labeling", "connectivity=4 type=[16 bits]");    
  cellLabelID= getImageID();
  rename("filteredCellLabel");
  
  
  run("Set Measurements...", "min redirect=None decimal=3");
  run("Measure");
  
  //if(nResults==0)
  //max_label_array = Table.getColumn("Max")
  if(getResult("Max", 0)==0)
  {
    print("NO CELL DETECTED FOR IMAGE "+baseName);
    
    close("*");
    
  selectWindow("Results");
  Table.reset("Results");
  run("Close");
    continue;
  }
  else
  {
    
  selectWindow("Results");
  Table.reset("Results");
  run("Close");
          
  //Remove the cell label based on the chloroplast max intensity
  selectImage(rawImageID);
  run("Duplicate...", "duplicate channels="+chloroplastChannel+"-"+chloroplastChannel);
  chloroplastID= getImageID();
  rename("chloroplast");
  run("Intensity Measurements 2D/3D", "input=chloroplast labels=[filteredCellLabel] max");
  chloroplastMaxArray=Table.getColumn("Max");
  label_to_remove_string="";
  ll=0;
  print("chloroplastMaxArray value:");
  for(l=0;l<chloroplastMaxArray.length;l++)
  {
    //print("label_to_remove_string:"+label_to_remove_string);
    if(chloroplastMaxArray[l]<maxIntensityChloroplast)
    {
      //print(chloroplastMaxArray[l] + "<"+maxIntensityChloroplast);
      //removedCellsArray[ll]=(l+1);
      
      label_value = d2s((l+1),0);
      if(label_to_remove_string=="")
      {
        //print("  IF label_to_remove_string:"+label_to_remove_string);
        label_to_remove_string=label_value;
        //print("  IF label_to_remove_string:"+label_value);
      }
      else
      {
        //print("  ELSE label_value:"+label_value);
        label_to_remove_string=label_to_remove_string+","+label_value;
        //print("  ELSE label_to_remove_string:"+label_to_remove_string);
      }
      ll=ll+1;
      //print(label_to_remove_string);
    }      
  }
  selectImage(chloroplastID);
  close();
  print("label_to_remove_string:"+label_to_remove_string);
  //lll
  if(label_to_remove_string!="")
  {
  
  selectImage(cellLabelID);  
  print("remove cells cluster IDs :"+label_to_remove_string);  
  run("Replace/Remove Label(s)", "label(s)="+label_to_remove_string+" final=0");  
  saveAs("Tiff", File.getParent(imageDir)+File.separator+"labels"+File.separator+baseName+".tiff");  
  //Reconvert to mask
  setThreshold(1, 65535, "raw");
  setOption("BlackBackground", true);
  run("Convert to Mask");
  selectImage(cellMaskID); 
  close();  
  selectImage(cellLabelID); 
  cellMaskID= getImageID();
  rename("cellmask");
  }
  else
  {
    selectImage(cellLabelID); 
    saveAs("Tiff", File.getParent(imageDir)+File.separator+"labels"+File.separator+baseName+".tiff");  
    close();
    selectImage(cellMaskID); 
    rename("cellmask");
  }
       
      
    //Measure the cell mask area
    run("Properties...", "channels=1 slices=1 frames=1 pixel_width="+pixelSize+" pixel_height="+pixelSize+" voxel_depth=1 frame=[NaN sec]");
    run("Analyze Particles...", "summarize");
    IJ.renameResults("Summary","Results") ;
    cell_mask_area = getResultString("Total Area", 0);    
    selectWindow("Results");
    run("Close"); 
    
    //Segment the probability mask
    selectImage(segImageID); 
    
		    //Save particlemask to check ROIs
		    selectImage(segImageID); 
		    run("Duplicate...", "duplicate channels=1");
		    saveAs("Tiff", imageDir+File.separator+baseName+"_particlemask.tiff");
		    close();
    
        selectImage(segImageID); 
    setThreshold(ParticleLabelValue, ParticleLabelValue, "raw");
    run("Convert to Mask");
   // if(doWatershed)
     // run("Watershed");
    //run("Convert to Mask");
    //Filter the particle by area
    run("Analyze Particles...", "size="+minParticleArea+"-Infinity pixel show=Masks in_situ"); //Masks in situ = image with filtered ones
             
    //Exclude particle on edge
    run("Analyze Particles...", "  show=Masks exclude in_situ");
    rename("particlemask");
            
    //Merge the cell mask and the particle mask
    imageCalculator("AND create", "cellmask","particlemask");
    particleImageId= getImageID();

	//run("Analyze Particles...", "  show=[Count Masks]");
     
  	selectImage(particleImageId);
  	if(doWatershed);
  	  run("Watershed");
   	run("Analyze Particles...", " show=[Count Masks] exclude add");  
    run("glasbey_on_dark");    
    particleLabelImageID=getImageID();
    nr_particle=roiManager("count");
    //Save particle if at least one is detected, otherwise skip
    if(nr_particle>0)
      roiManager("Save", imageDir+File.separator+baseName+"_rois.zip");
    roiManager("Reset"); 
	
    //selectImage(imageID);
    selectImage(particleLabelImageID);
    Stack.setXUnit("um");
    run("Properties...", "channels=1 slices=1 frames=1 pixel_width="+pixelSize+" pixel_height="+pixelSize+" voxel_depth=1 frame=[NaN sec]");
    run("Analyze Regions", analysisRegionCom);
    //Produce a table name "Count"+"-Morphometry"
    
    
    selectImage(rawImageID);
    run("Duplicate...", "duplicate channels=1-1");
    rename("c1");
    particleChannelID= getImageID();
    run("Intensity Measurements 2D/3D", "input=c1 labels=[Count Masks of Result of cellmask] mean max median");
    //lll
    //produce table named "c1"+"-intensity-measurements"
    
    concatenate_table("Count"+"-Morphometry", "c1"+"-intensity-measurements");
    
    //CLose the last open result table
    selectWindow("c1"+"-intensity-measurements");
    run("Close" );
    
        if(i==0)
    {
      columns=split(Table.headings, "\t"); 
      print("File\t"+Table.headings);
      File.append("File\tCell Area\t"+Table.headings,resultTxtFile);
      print("Write into file "+resultTxtFile);
    }
    
    //Table.rename("result_tmp.txt", "Results") ;
    print("nResults:"+nResults);
    IJ.renameResults("Count"+"-Morphometry","Results") ;
    number_of_particle = nResults;
    for (r=0; r<number_of_particle; r++) {
      row=baseName+"\t"+cell_mask_area;
      for(c=0;c<columns.length;c++)
      {
        row=row+"\t"+ getResultString(columns[c], r);
      }
      File.append(row,resultTxtFile);
      //IJ.renameResults("Results","Count"+"-Morphometry") ;
      /*
      IJ.renameResults("c1"+"-intensity-measurements","Results") ;
      for(c=0;c<columns2.length;c++)//Skip the File one
      {
        row=row+"\t"+ getResultString(columns2[c], r);
      }
      IJ.renameResults("Results","c1"+"-intensity-measurements") ;
      
      //IJ.renameResults("Count"+"-Morphometry","Results") ;
      */
    }
    IJ.renameResults("Results","Count"+"-Morphometry") ;
    //run("Clear Results");
    //selectWindow("c1"+"-intensity-measurements");
    //run("Close"); 
    selectWindow("Count"+"-Morphometry");
    run("Close"); 
    
    //Close the image
    selectImage(rawImageID);
    close();
    selectImage(segImageID);
    close();
    selectImage(cellMaskID);
    saveAs("PNG", imageDir+File.separator+baseName+"_cell_mask.png");
    close();
    selectImage(particleImageId);
    close();
    selectImage(particleChannelID);
    close();
    selectImage(particleLabelImageID);
    //saveAs("Tiff", imageDir+File.separator+baseName+".tiff");
    close();
    
    // Duplicates created by Ellen - to be closed
    selectImage(particleImageId3);
    close();
    selectImage(particleImageId2);
    close();
    //selectImage(dupID2);
    //close();
    close("*");
    print("Finished file "+baseName);
  }
}
setBatchMode(false);
print("Saved in "+resultTxtFile);

//Return a file list contain in the directory dir filtered by extension.
function getFilesList(dir, fileExtension) {  
  tmplist=getFileList(dir);
  list = newArray;
  imageNr=0;
  for (i=0; i<tmplist.length; i++)
  {
    if (endsWith(tmplist[i], fileExtension)==true)
    {
      list[imageNr]=tmplist[i];
      imageNr=imageNr+1;
    }
  }
  Array.sort(list);
  return list;
}

/**
 *  Return the BaseName of a file name, e.g. test.tif -> test
 *  
 * :param str fileName: the file name (e.g., test.tif)
 */
function getBasename(fileName){
  dotIndex =  lastIndexOf(fileName, ".");
  //print(""+dotIndex);
  //basename=substring(fileName, 0, lengthOf(fileName)-4); 
  basename = substring(fileName, 0, dotIndex);
  return basename;
}

function concatenate_table(table1_name, table2_name)
{
  selectWindow(table1_name);
  //Table.create(output_table_title);
  headings = Table.headings;
  headingsArray = split(headings, "\t");
  /*
  for(h=0; h<headingsArray.length;h++)
  {
    if(headingsArray[h]!="Label")
      Table.renameColumn(headingsArray[h],marker_1_name+" "+headingsArray[h]);
  }
  */
  
  selectWindow(table2_name);  
  headings = Table.headings;
  headingsArray = split(headings, "\t");
  for(h=0; h<headingsArray.length;h++)
  {
    selectWindow(table2_name);
    header = headingsArray[h];
    if(header!=" " && header!="Label")//Skip the empty header column
    {
      //print("Header:"+header);
      columnContent = Table.getColumn(headingsArray[h]);
      selectWindow(table1_name);
      for (r=0; r<columnContent.length; r++)
      {
         Table.set(headingsArray[h], r, columnContent[r])
         //setResult(headingsArray[h], analysisRowsNumber+r, columnContent[r]);
      }
      Table.update;
    }
  }
}