//@ File(label="Choose an Image Directory", style="directory") imageDir
//@ Integer (label="Channel", description="select the channel to", value=1) channel
//@ Integer (label="Median filter", description="Median filter sigma", value=1) medianFilter
//@ String(label="Slices for Ilastik training [Optional]", description="slice list to use for the Ilastik stack separated by comma, e.g. 1,4,7") slices_to_subtract

//Read nd2 file, delete slice rnage if needed, otherwise set the paramaeters to 0,  perform Maximum intensity Projection and save the result in the same folder

//Requirement:
// Fiji

//2023/01/10
//Author: Benjamin Pavie - benjamin.pavie@vib.be
//        VIB BioImaging Core
//Please acknowledge us if you use this script in a publication.

imageExtension="nd2";
imageList = getFilesList(imageDir,imageExtension);
image_name_list = newArray(imageList.length);
//Remove the image names file if exist already
if(File.exists(imageDir+File.separator+"stack_image_file_names.txt"))
  File.delete(imageDir+File.separator+"stack_image_file_names.txt");
image_file_name_file = File.open(imageDir+File.separator+"stack_image_file_names.txt");


//setBatchMode("hide");
for (i=0; i<imageList.length; i++){
  fileName=imageList[i];
  IJ.log("Processing image "+fileName);
  baseName=getBasename(fileName);
  print(image_file_name_file, baseName);
  image_name_list[0]=baseName;
  imagePath=imageDir+File.separator+fileName;
  
  run("Bio-Formats Importer", "open=["+imagePath+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
  
  raw_id = getImageID();
  
  /*
  if(firstSliceToDelete>0 && lastSliceToDelete>0 )
    run("Delete Slice Range", "first="+firstSliceToDelete+" last="+lastSliceToDelete);
  */
  run("Duplicate...", "duplicate channels="+channel+"-"+channel);
  channel_id = getImageID();
  run("Z Project...", "projection=[Max Intensity]");  
  mip_id = getImageID();
  selectImage(raw_id);
  close(); 
  selectImage(channel_id);
  close(); 
  selectImage(mip_id);
  
  
  
  
  if(i==0)
  {
    rename("stack");
  }
  else
  {
    rename("toConcatenate");
    run("Concatenate...", "  title=stack image1=stack image2=toConcatenate image3=[-- None --]");
  }
}
//setBatchMode("show");
selectWindow("stack");
stack_id=getImageID();
saveAs("Tiff", imageDir+File.separator+"stack_raw.tiff");  

//Normalize the slices 
run("Enhance Contrast...", "saturated=0.1 normalize process_all use");

if(slices_to_subtract!="")
{
  run("Make Substack...", "  slices="+slices_to_subtract);
  rename("Ilastik Training Stack");
  subtrack_id = getImageID();
  selectImage(subtrack_id);
  run("Median...", "radius="+medianFilter+" stack");
  saveAs("Tiff", imageDir+File.separator+"substack_ilastik_training.tiff"); 
} 

File.close(image_file_name_file);
selectImage(stack_id);
run("Median...", "radius="+medianFilter+" stack");
saveAs("Tiff", imageDir+File.separator+"stack_normalized.tiff");  
IJ.log("Processing Done!");

/**
 *  Return a file list contain in the directory dir filtered by extension.
 *  
 * :param str dir: the directory where the files are located
 * :param str fileExtension: the file extension use to filter the list, e.g. tif
 * 
 * return a list of relative file path, relative to the directory dir path
 */
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
 * 
 * return the basename, e.g. from test.tif return test
 */
function getBasename(fileName){
  dotIndex =  lastIndexOf(fileName, ".");
  //print(""+dotIndex);
  //basename=substring(fileName, 0, lengthOf(fileName)-4); 
  basename = substring(fileName, 0, dotIndex);
  return basename;
}

