#@ File(label="Select the image Directory", style="directory") imageDir
#@ File(label="Select the segmentation Directory", style="directory") segmentationDir
#@ File(label="Select the cell label Directory", style="directory") cellLabelDir
#@ Double(label="Pixel size in um", value="0.1035801") pixelSize

#@ String (visibility=MESSAGE, value="<html><b>Cell Segmentation Parameters</b></html>", required=false) msg
#@ Integer(label="Maximum Cell Area [px]", value="6000") seg_minCellArea

#@ String (visibility=MESSAGE, value="<html><b>Particle Segmentation Parameters</b></html>", required=false) msg2
#@ Integer(label="Particle Label value", value="1") ParticleLabelValue
#@ Integer(label="Minimum Particle area [px]", value="2") minParticleArea
#@Boolean (label="Watershed Particule", value=false) doWatershedForParticule

#@ String (visibility=MESSAGE, value="<html><b>Cell Features</b></html>", required=false) msg3
#@Integer(label="Channel intensity to measure", value="1") cellChannelToMeasure
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

//Build the command given the boolean selection
//Author: Benjamin Pavie - benjamin.pavie@vib.be

analysisRegionCommand = newArray();

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

//List all the h5 files
list =getFilesList(imageDir, "tif");
list_segmentation =getFilesList(segmentationDir, "tiff");
list_labels =getFilesList(cellLabelDir, "tiff");

///Save results file in dir1 with specified headings
resultTxtFile=cellLabelDir+File.separator+"result_per_cells.txt";
//Delete the previous result file
if(File.exists(resultTxtFile))
  File.delete(resultTxtFile);
  
///Save results file in dir1 with specified headings
resultTxtFilePerParticle=cellLabelDir+File.separator+"result_per_particle.txt";
//Delete the previous result file
if(File.exists(resultTxtFilePerParticle))
  File.delete(resultTxtFilePerParticle);

for (f=0; f<list.length; f++) 
{
  original_path = imageDir+File.separator+list[f];
  segmentation_path = segmentationDir+File.separator+list_segmentation[f];
  
  cell_label_path = cellLabelDir+File.separator+list_labels[f];
  baseName=getBasename(list[f]);
  IJ.log("Processing file "+baseName); 
  IJ.log("  Raw file "+original_path); 
  IJ.log("  Segmentation file "+segmentation_path);

  setOption("ExpandableArrays", true);
  particlePerCellArray=newArray();
  particleAreaPerCellArray=newArray();

  run("Bio-Formats", "open=["+original_path+"] " +"autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
  rawImageID= getImageID();
 
  // To save image for checking LB or cell ROIs later on
  selectImage(rawImageID);
  run("Duplicate...", "duplicate channels=1"); 
  run("Enhance Contrast...", "saturated=0.1");
  run("Yellow");
  saveAs("Tiff", cellLabelDir+File.separator+baseName+"_channel1.tif");
  close();    
  selectImage(rawImageID);
  run("Duplicate...", "duplicate channels=1-3");
  combinedImageID= getImageID();
  rename("combine");
  run("Split Channels");
  selectWindow("C1-combine");
  run("Enhance Contrast...", "saturated=0.1");
  run("Yellow");
  selectWindow("C2-combine");
  run("Red");
  selectWindow("C3-combine");
  run("Cyan");
  run("Merge Channels...", "c1=[C2-combine] c5=[C3-combine] c7=[C1-combine] create");
  saveAs("Tiff", cellLabelDir+File.separator+baseName+"_channel1-3.tif");
  close();  
   
  selectImage(rawImageID);
  //Segment the cells
  roiManager("reset");
  open(cell_label_path);
  unfilteredCellLabelID = getImageID();
  run("Label Size Filtering", "operation=Lower_Than size="+seg_minCellArea);
  cellLabelFilteredID= getImageID();
  run("Remove Border Labels", "left right top bottom");
  cellLabelID= getImageID();
  selectImage(unfilteredCellLabelID); 
  close();
  selectImage(cellLabelFilteredID); 
  close();
  
  // save cellmask
  selectImage(cellLabelID); 
  run("Duplicate...", "duplicate channels=1");
  saveAs("Tiff", cellLabelDir+File.separator+baseName+"_cell mask.tif");
  close();

  //Analysis Per Cells
  selectImage(cellLabelID);
  rename("cellLabel");
  //Get max cells
  run("Set Measurements...", "area mean min redirect=None decimal=3");
  //Relabel just to be sure
  run("Remap Labels");
  //Measure to get the Max intensity
  run("Measure");
  number_of_cells=getResultString("Max", 0);
  selectWindow("Results");
  run("Close");   
  
  //Open the particle segmentation matching image
  run("Bio-Formats", "open=["+segmentation_path+"] " +"autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
  rename("particleSeg");
  particleSegID= getImageID();
  
  //Segment the particle, which should be labbeled to 1?
  setThreshold(ParticleLabelValue, ParticleLabelValue, "raw");
  run("Convert to Mask");
          
  //Filter the particle by area
  run("Analyze Particles...", "size="+minParticleArea+"-Infinity pixel show=Masks in_situ"); //Masks in situ = image with filtered ones
  
  //Prepare the array to compute particle measurement per cell
  for(i=0;i<number_of_cells;i++)
  {
    particlePerCellArray[i]=0;
    particleAreaPerCellArray[i]=0;
  }
  
  selectImage(cellLabelID);
  run("Duplicate...", "duplicate channels=1-1");
  setThreshold(1, 65535, "raw");
  run("Convert to Mask");
  cellMaskID= getImageID();
  rename("cellMask");
  
  selectImage(cellMaskID);
  run("Divide...", "value=255");
  imageCalculator("Multiply create", "particleSeg","cellMask"); //filter particles inside cells
  filteredParticleSegID= getImageID();
  
  getStatistics(area, mean, min, max, std, histogram);  
  if(max >0)
  {
    print("NO PARTICLE DETECTED WITHIN THE CELL MASK!");
  }
  
  rename("filteredParticleSeg");  
  run("Properties...", "channels=1 slices=1 frames=1 pixel_width="+pixelSize+" pixel_height="+pixelSize+" voxel_depth=1 frame=[NaN sec]");
  if(doWatershedForParticule)
    run("Watershed");
                        
  filteredParticleSegID2= getImageID();
  if(max>0)
  {
    run("Analyze Particles...", "  show=[Count Masks] add");
    roiManager("Save", cellLabelDir+File.separator+baseName+"_filtered_particle_rois.zip");
    
    filteredParticleSegLabelID= getImageID();
    rename("filteredParticleSegLabel");  
  
    selectImage(cellLabelID);
    Stack.setXUnit("um");
    run("Properties...", "channels=1 slices=1 frames=1 pixel_width="+pixelSize+" pixel_height="+pixelSize+" voxel_depth=1 frame=[NaN sec]");
    roiManager("Measure");
    number_of_particle = nResults;
    for (row=0; row<number_of_particle; row++) {
      cell_id = getResult("Min", row);
      particle_area = getResult("Area", row);
      particlePerCellArray[cell_id-1]=particlePerCellArray[cell_id-1]+1;
      particleAreaPerCellArray[cell_id-1]=particleAreaPerCellArray[cell_id-1]+particle_area;
    }
    selectWindow("Results");
    Table.reset("Results");
    run("Close");  
  }
  
  //Measure the intensity of specific channel
  selectImage(rawImageID);
  run("Duplicate...", "duplicate channels="+cellChannelToMeasure+"-"+cellChannelToMeasure);
  cellChannelID= getImageID();
  rename("c"+cellChannelToMeasure);
  particleChannelID= getImageID();
  //Run the intensity measurement from the cell labels
  run("Intensity Measurements 2D/3D", "input="+"c"+cellChannelToMeasure+" labels=[cellLabel] mean max median");
  //Run the shape measurement from the cell labels
  selectImage(cellLabelID);
  Stack.setXUnit("um");
  run("Properties...", "channels=1 slices=1 frames=1 pixel_width="+pixelSize+" pixel_height="+pixelSize+" voxel_depth=1 frame=[NaN sec]");
  run("Analyze Regions", analysisRegionCom);
  //Merge both results 
  concatenate_table("cellLabel"+"-Morphometry", "c"+cellChannelToMeasure+"-intensity-measurements");
  IJ.renameResults("cellLabel"+"-Morphometry","Results") ;
  //Close the left over result table  
  selectWindow("c"+cellChannelToMeasure+"-intensity-measurements");
  run("Close");
  selectWindow("Results");
  //Write the header
  columns=split(Table.headings, "\t"); 
  //Write the header only for the first image file
  if(f==0)
  {
    new_header = "File\t"+Table.headings+"\tNumber of Particle\tParticle Area";
    new_header = replace(new_header, "\t ", "");
    File.append(new_header, resultTxtFile);
  }
  for (i=0; i<number_of_cells; i++) {
    row=baseName+"\t"+(i+1);
    
    for(c=2;c<columns.length;c++)
    {
      row=row+"\t"+ getResultString(columns[c], i);
    }
    row = row +"\t"+particlePerCellArray[i]+"\t"+particleAreaPerCellArray[i];
    
    File.append(row,resultTxtFile);
  }
  
  //Analysis per particule instead of per cell  
  selectWindow("Results");
  Table.reset("Results");
  run("Close");  
  roiManager("reset");  
  if(max>0)
  {
    selectImage(filteredParticleSegLabelID);
    Stack.setXUnit("um");
    run("Properties...", "channels=1 slices=1 frames=1 pixel_width="+pixelSize+" pixel_height="+pixelSize+" voxel_depth=1 frame=[NaN sec]");
    run("Analyze Regions", analysisRegionCom);    
    
    //TODO make it a parameters
    selectImage(rawImageID);
    run("Duplicate...", "duplicate channels=1-1");
    rename("c1");
    particleChannelID= getImageID();
    run("Intensity Measurements 2D/3D", "input=c1 labels=[filteredParticleSegLabel] mean max median");
    //produce table named "c1"+"-intensity-measurements"
    
    if(isOpen("filteredParticleSegLabel"+"-Morphometry"))
    {
      concatenate_table("filteredParticleSegLabel"+"-Morphometry", "c1"+"-intensity-measurements");      
      //Close the last open result table
      selectWindow("c1"+"-intensity-measurements");
      run("Close" );      
      //Grab the cell ID for each particle
      run("Intensity Measurements 2D/3D", "input=cellLabel labels=[filteredParticleSegLabel] max");
      IJ.renameResults("cellLabel"+"-intensity-measurements","Results") ;
      particle_cell_id_array = Table.getColumn("Max");
      selectWindow("Results");
      Table.reset("Results");
      run("Close");    
      IJ.renameResults("filteredParticleSegLabel"+"-Morphometry", "Results");
      if(f==0)
      {
        columns=split(Table.headings, "\t");
        File.append("File\tCell Id\t"+Table.headings,resultTxtFilePerParticle);
        print("Write into file "+resultTxtFilePerParticle);
      }
      number_of_particle = nResults;
      for (r=0; r<number_of_particle; r++)
      {
        row=baseName+"\t"+particle_cell_id_array[r]+"\t";//+cell_mask_area;
        for(c=1;c<columns.length;c++)
        {
          row=row+"\t"+ getResultString(columns[c], r);
        }
        File.append(row,resultTxtFilePerParticle);
      }
    }
    else
    {
      print("No particle detected after filtering for File "+baseName);
    }  
  }
  
  //Clean  
  selectImage(cellChannelID); 
  close();
  selectImage(rawImageID); 
  close();
  selectImage(cellLabelID); 
  close();
  selectImage(particleSegID); 
  close();
  selectImage(cellMaskID); 
  close();
  selectImage(filteredParticleSegID); 
  close();
  if(max>0)
  {
    selectImage(particleChannelID);
    close();
    selectImage(filteredParticleSegLabelID);
    close();
  }    
  if(isOpen("Results"))
  {
    selectWindow("Results");
    Table.reset("Results");
    run("Close"); 
  }
  roiManager("reset");
  run("Close All");
  
}//End of looping per image file

//Add the mean of particle intensity per cell

Table.open(resultTxtFilePerParticle);
IJ.renameResults("result_per_particle.txt", "Results");

setOption("ExpandableArrays", true);
imageNameArrayPerCell=newArray();
cellIDArrayPerCell=newArray();
imageNameCellIDArrayPerCell=newArray();
meanOfMeanIntensityParticlePerCell=newArray();
sumOfMeanIntensityParticlePerCell=newArray();
numberOfParticlePerCell=newArray();

imageNameArray=Table.getColumn("File");
cellIDArray=Table.getColumn("Cell Id");
particleIDArray=Table.getColumn("Label");
meanIntensityPerParticleArray=Table.getColumn("Mean");

cell_number=0;
previous_cell_name = "";
particle_count=0;
particleMeanIntensitySum=0;
previous_cell_id="";
previous_imageName="";
for (p = 0; p < nResults; p++) {
  imageName = Table.getString("File",p);
  cellId = Table.getString("Cell Id",p);
  particleId = Table.getString("Label",p);
  particleMeanIntensity = Table.get("Mean",p);    
  cell_name = imageName+cellId;
  imageNameCellID = imageName+",,"+cellId;    
  if(contains( imageNameCellIDArrayPerCell, imageNameCellID )==false)
  {
    imageNameCellIDArrayPerCell[cell_number]=imageNameCellID;
    sumOfMeanIntensityParticlePerCell[cell_number]=particleMeanIntensity;
    numberOfParticlePerCell[cell_number]=1;
    cell_number=cell_number+1;
  }
  else {
    row_number = get_first_row_containing_value( imageNameCellIDArrayPerCell, imageNameCellID );
    sumOfMeanIntensityParticlePerCell[row_number]=sumOfMeanIntensityParticlePerCell[row_number]+particleMeanIntensity;
    numberOfParticlePerCell[row_number]=numberOfParticlePerCell[row_number]+1;
  }
}  

//Close the previous results table
selectWindow("Results"); 
run("Close");

filePath=cellLabelDir+File.separator+"result_per_cells.txt";
Table.open(filePath);
IJ.renameResults("result_per_cells.txt", "Results");
updateResults();
print(Table.headings);
file_column=Table.getColumn("File", "Results");
label_column = Table.getColumn("Label", "Results");

for(c=0; c<cell_number;c++)
{
  result=split(imageNameCellIDArrayPerCell[c],",,");
  fileName = result[0];
  cell_id = result[1];
  mean_particle_intensity = sumOfMeanIntensityParticlePerCell[c]/numberOfParticlePerCell[c];  
  rowIndex=getRowNumberForResultTable(fileName, file_column, cell_id, label_column);
  if(rowIndex==-1)
    print(imageNameCellIDArrayPerCell[c]+" : Not found cell_id"+" in fileName:"+fileName+" / "+cell_id);
  else  
    Table.set("Particle Mean Intensity", rowIndex, mean_particle_intensity);
  updateResults();
}
//Resave the file
saveAs("Results", filePath);

showMessage("Analysis Done", "<html><h1>Analysis is Done</h1><p> Results file have been saved in "+cellLabelDir+"</p></html>");

function getRowNumberForResultTable(value1, col1, value2, col2)
{
  col1_value_rows = get_rows_containing_value( col1, value1 );
  col1_value_rows_result="";
  for(cc=0;cc<col1_value_rows.length;cc++)
  {
    col1_value_rows_result = col1_value_rows_result+"-"+col1_value_rows[cc];
  }  
  for(r=0;r<col1_value_rows.length;r++)
  {
    if(col2[col1_value_rows[r]]==value2)
    {
      return col1_value_rows[r];
    }
  }
  return -1;  
}

function contains( array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return true;
    return false;
}


function get_first_row_containing_value( array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return i;
    return -1;
}

function get_rows_containing_value( array, value ) {
  row_list = newArray();
    for (i=0; i<array.length; i++)
    {
        if ( array[i] == value )
        {
          row_list=Array.concat(row_list, i);
        }
    }
    return row_list;
}

function segment_round_cells(rawImageID, channels, saturation, minCellArea, chloroplastChannel, maxIntensityChloroplast)
{
  setOption("ExpandableArrays", true);
  channelList =  split(channels, ",");
  imageNameArray=newArray();
  imageIDArray=newArray();
  
  for(i=0; i<channelList.length;i++)
  {
    selectImage(rawImageID);
    run("Duplicate...", "duplicate channels="+channelList[i]+"-"+channelList[i]);
    run("Enhance Contrast...", "saturated"+saturation);
    //run("Brightness/Contrast...");
    run("Apply LUT");
    rename("c"+channelList[i]);
    imageIDArray[i]=getImageID();
    imageNameArray[i]="c"+channelList[i];
  }
  if(imageNameArray.length>1)
  {
    //Merge the channels
    merge_string="";
    
    for(i=0;i<imageNameArray.length;i++)
    {
      merge_string=merge_string+"c"+(i+1)+"="+imageNameArray[i]+" ";
    }
    
    print(merge_string);
    
    run("Merge Channels...", merge_string+"create");
    mergedImageID= getImageID();
    //Blur all
    run("Gaussian Blur...", "sigma=2");
    run("Properties...", "channels=1 slices="+imageNameArray.length+" frames=1 pixel_width=0.1035801 pixel_height=0.1035801 voxel_depth=1");
    run("Z Project...", "projection=[Max Intensity]");
  }
  projectionImageID= getImageID();
  
  selectImage(projectionImageID);
  
  run("Enhance Contrast...", "saturated"+saturation);
  //run("Brightness/Contrast...");
  run("Apply LUT");
  rename("projection");
  run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], 
  args=['input':'projection', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'0.0', 
  'percentileTop':'99.8', 'probThresh':'0.75', 'nmsThresh':'0.3', 'outputType':'Both', 
  'modelFile':'C:\\\\Users\\\\u0094799\\\\Code\\\\customizedStardist\\\\models\\\\stardist_julie\\\\TF_SavedModel.zip', 'nTiles':'1', 
  'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
  
  labelImageID= getImageID();
  run("Label Size Filtering", "operation=Greater_Than size="+minCellArea);
  filteredLabelImageID= getImageID();
  
  
  selectImage(filteredLabelImageID);
  run("Remove Border Labels", "left right top bottom");
  filteredNoBorderLabelImageID= getImageID();
  rename("filteredCellLabel");
  
  //Relabel
  run("Remap Labels");
  selectImage(filteredLabelImageID);
  close();
  
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
  selectImage(filteredNoBorderLabelImageID);  
  print("remove cells :"+label_to_remove_string);  
  run("Replace/Remove Label(s)", "label(s)="+label_to_remove_string+" final=0");
  
  //Relabel
  run("Remap Labels");
  
  selectWindow("chloroplast-intensity-measurements");
  run("Close"); 
  
  //Convert label to ROIs
  selectImage(filteredNoBorderLabelImageID);  
  roiManager("reset");
  run("Colors...", "foreground=white background=black selection=yellow");
  run("Options...", "iterations=1 count=1 black do=Nothing");
  run("Label Boundaries");
  boundaryID= getImageID();
  run("Invert");
  run("Remove Largest Region");
  tmp_labelID= getImageID();
  run("Analyze Particles...", "add");
  selectImage(tmp_labelID);
  close();
  selectImage(boundaryID);
  close();
  
  if(imageNameArray.length>1)
  {
    selectImage(mergedImageID);
    close();
  }
  selectImage(labelImageID);
  close();
  selectImage(projectionImageID);
  close();
  
  return filteredNoBorderLabelImageID;
}

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