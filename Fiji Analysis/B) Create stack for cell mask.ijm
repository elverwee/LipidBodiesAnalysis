//@File(label="Select the image Directory", style="directory") imageDir
//@File(label="Select the output Directory", style="directory") outputDir

// Convert tiff to h5

// Requirement:
// - Bio-format
// - ilastik for Fiji : https://www.ilastik.org/documentation/fiji_export/plugin

//Benjamin Pavie benjamin.pavie@vib.be
//VIB Bio-Imaging Core Facility
//2023/04/04
//Please acknowledge us if you use this script in a publication.


list =getFilesList(imageDir, "tif");

for (i=0; i<list.length; i++) 
{
    baseName=getBasename(list[i]);
    original_path = imageDir+File.separator+list[i];
    
    
    run("Bio-Formats", "open=["+original_path+"] " +"autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
    rename("raw");
    rawImageID= getImageID();
    run("Median...", "radius=1 stack"); 
    run("Export HDF5", 
    "select=["+outputDir+File.separator+baseName+".h5] exportpath=["+outputDir+File.separator+baseName+".h5] datasetname=data compressionlevel=0 input=[raw]");    
    selectImage(rawImageID); 
    close();

}
showMessage("Analysis Done", "<html><h1>Conversion from TIFF to H5 is Done</h1><p> Results file have been saved in "+outputDir+"</p></html>");

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