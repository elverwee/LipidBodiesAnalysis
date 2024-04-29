############################################################################################
#### Original by Joost Verduijn 15/07/2021, Edited by Ellen Verwee                      ####
#### Laboratory of Nano-Biotechnology, Department of Biotechnology, Ghent University    ####
#### Johannes.Verduijn@ugent.be                                                         ####
############################################################################################

#### PART A: Basic data processing of Raman large area scans

#### Delete variables
rm(list = ls()) 


#### File and package loading
setwd("C:\\Users\\xxxxxx")

files=list.files(pattern=".spc",recursive=TRUE)  #Loads all .spc files (each .spc file contains spectra from one Raman large are scan (LAS) ) from subfolders
library(vegan)
library("stringr")
library("hyperSpec") # hyperSpec package
library("baseline") # Contains all kinds of functions for baseline removal
#library(MALDIquant)
library(gridExtra )
library(DescTools) #for AUC function
library('hyperSpec.utils') #install.packages("remotes") #remotes::install_github("konradmayer/hyperSpec.utils")
library("ggplot2") 


#### Retrieve LAS characteristics for use in function later on 
xList=as.numeric(sub("x.*", "",sub(".spc","",sub(".*_","",files)))) #get x size from LAS file name 
yList=as.numeric(sub(".*x", "",sub("-.*","",files))) #get y size from LAS file name 
SizeList=as.numeric(sub(".*-", "",sub(".spc","",files))) #gets step size ( XX µm per pixel) from LAS file name


#### Function to analyse each large area scan, with f=file, x=xList, y=yList,Size=SizeList
#### Background subtraction, baseline correction, normalisation
AnalyzeSingleCell <- function(f, x=1, y=1, Size=1){
                   #x and y= 1 if work with single spectra
  hs=read.spc(f)
  #select the area (wavenumbers) of interest
  hs=hs[,,600~1800] 
  wavelengths <- hs@wavelength #get wavelengths
  pxl <- (1/Size)
  ppl <- x*pxl
  lines <- y*pxl
  
  #Dataframe giving X and Y coordinates to each spectra
  XY <- data.frame(cbind(rep((1:ppl)*1/pxl,lines),rep((1:lines)*1/pxl,each=ppl))) 

  colnames(XY) <- c("X","Y")
  hs$x <- XY$X
  hs$y <- sort(XY$Y, decreasing=TRUE)
  #labels(hs,"x") <- as.character("x / ?m")
  #labels(hs,"y") <- as.character("y / ?m")
  hs.raw = hs #hs.temp is only used in export (so is obsolete)
  ### Create baseline per LAS
  b<-baseline(hs$spc,method="modpolyfit",degree=5) 
  #plot(b)
  hs$spc=getCorrected(b)
  
  # Normalisation via package hyperspec.utils 
  hs.base<-hs
  hs.norm<-area_normalization(hs,FUN="sum")
  hs.norm$spc<-hs.norm$spc*100000  #Increase relative intensities, it is normalized data anyway
  
#outputs the Hyperspec(HS), the normalized HS and the clustered HS (in case you use cell.HCA lines above)
#Add the new factors to the Global environment
newList <- list("hs.raw" = hs.raw, "hs.norm" = hs.norm,"hs.base"=hs.base)#, "Cell.HCA"=Cell.HCA
list2env(newList ,.GlobalEnv)
}

## Use the function for all files

#Create an empty HysperSpec object to append to
EmptyHs=read.spc(files[1])
EmptyHs=EmptyHs[,,600~1800]
Cell.HCA_total<-empty(EmptyHs)
Cell.raw<-empty(EmptyHs)
Cell.base<-empty(EmptyHs)

#For all files, run function, and add them together in one hyperspec file (via rbind)
for (i in 1:length(files)){ #1:length(files)
  AnalyzeSingleCell(files[i],xList[i], yList[i],SizeList[i]) #Remove background+Normalize+HCA
                              
  Cell.HCA_total<-rbind2(Cell.HCA_total, hs.norm, wl.tolerance=0.3) 
  print(files[i])
}

Cell.HCA_total$file_spc<-as.factor(basename(Cell.HCA_total$filename)) #assign file name 
Cell.HCA_total$group<-as.factor(dirname(Cell.HCA_total$filename)) # assign directory name





#### PART B: Cluster the spectra for each of the large area scan present in the Cell.HCA.total file
####          In order to visualise the lipid bodies in the cells


#Cluster whole hyperspec (outisde of loop)
Cell.HCA_total$cluster_cell_backgr<-as.factor(kmeans(Cell.HCA_total[[]],2)$cluster)  

#Gives the clusternumber of smallest cluster for that particular LAS
k_means_Allcells<-which.max(tabulate(Cell.HCA_total$cluster_cell_backgr))


EmptyHs2=read.spc(files[1])
EmptyHs2=EmptyHs2[,,600~1800]
Cell.HCA_total_filter_cluster_of_cluster2<-empty(EmptyHs2)
#Loop: kiezen kleinste cluster 
for (qq in 1:length(files)){
  # Select 1 large area scan (via unique name)
  SelectionVector_Cluster_of_cluster<-Cell.HCA_total$file_spc==unique(Cell.HCA_total$file_spc)[qq]
  
  print(k_means_Allcells)
  # take smallest cluster of that large area scan (= cell) and link spectra to that clusternumber
  Cell.HCA_total_filter_per_cell2<-
      Cell.HCA_total[Cell.HCA_total$cluster_cell_backgr==k_means_Allcells&SelectionVector_Cluster_of_cluster]
  # combine all smallest clusters of each large area scan (= all cells) 
  Cell.HCA_total_filter_cluster_of_cluster2<-
      rbind2(Cell.HCA_total_filter_per_cell2,Cell.HCA_total_filter_cluster_of_cluster2, wl.tolerance=0.3)
  
}

#saveRDS(Cell.HCA_total, file = "FILENAME.rds")

# Cluster within total_filter = cluster again the smallest clusters (smallest clusters are the cells).
# This way, additional clustering is not forced if there is nothing to cluster in that particular cell.

Cell.HCA_total_filter_cluster_of_cluster2$kmeans3<-
  as.factor(kmeans(Cell.HCA_total_filter_cluster_of_cluster2[[]],2)$cluster)  

#Cell.HCA_total_filter_cluster_of_cluster=Cell.HCA_total_filter_cluster_of_cluster[,,1400~1500]




#### PART C: Examples for plotting 

# Create 'FigureFolder' to store saved plots  
FigureFolder<-"C:\\Users\\xxxxx"


for (z in 1:length(files)){
      plot_spc <-Cell.HCA_total[Cell.HCA_total$file_spc==unique(Cell.HCA_total$file_spc)[z]] #store for use within loop
    
      q1<-plotmap(Cell.HCA_total[Cell.HCA_total$file_spc==unique(Cell.HCA_total$file_spc)[z]],
                  cluster_cell_backgr~x*y, col.regions = topo.colors(5))
     
      q5<-plotmap(Cell.HCA_total_filter_cluster_of_cluster2[Cell.HCA_total_filter_cluster_of_cluster2$file_spc==unique(Cell.HCA_total$file_spc)[z]],
                  kmeans3~x*y, col.regions = topo.colors(5))

      #Plotmap lipid peak
      pLB<-plotmap(plot_spc[,,1437~1443],spc~x*y,func.args = list(na.rm = TRUE),col.regions = heat.colors(100)) 
 
      # Ratio plot
      plot_spc$ratio <-rowMeans(plot_spc[,,1437~1443]$spc)/rowMeans(plot_spc[,,1447~1453]$spc)
      pRatio<-plotmap(plot_spc,ratio~x*y, col.regions = topo.colors(100))
      
      # Example to save in folder
      ggsave(plot = pRatio,filename = paste0(FigureFolder,"\\",sub(".spc","",unique(Cell.HCA_total$file_spc)[z]),"ClusterDataset.png"),width=1920,height=1137,unit="px", device = "png")
}

    
library('viridis')
library('RColorBrewer')    

# Example of a specific plot with adapted colors for better visualisation of lipid peak near 1440 cm-1 (lipid body),
# based on the ratio with the peak near 1452 cm-1 (chloroplast)
LAS005<-Cell.HCA_total[Cell.HCA_total$file_spc=="LAS005_9x9-0.45.spc"]
LAS005_cell<-Cell.HCA_total_filter_cluster_of_cluster[Cell.HCA_total_filter_cluster_of_cluster$file_spc=="LAS005_9x9-0.45.spc"]
LAS005_cell<-subset(LAS005_cell,LAS005_cell$x>3&LAS005_cell$x<7 & LAS005_cell$y>2.8&LAS36_cell$y<6)
      
      LAS005_cell$ratio <-rowMeans(LAS005_cell[,,1437~1443]$spc)/rowMeans(LAS005_cell[,,1449~1455]$spc)
      LAS005_cell$ratio<-ifelse(LAS005_cell$ratio<0.8,0.8,LAS005_cell$ratio) 
      LAS005_cell$ratio2<-ifelse(LAS005_cell$ratio>1.2,1.2,LAS005_cell$ratio)
      
    p3<-qplotmap(LAS005_cell, mapping = aes_string(x = "x", y = "y", fill = "ratio2"))
    p3<-p3 + scale_fill_gradient2(
        low = "royalblue",
        mid = "purple",
        high = "yellow",
        limits=c(0.8,1.2),
        midpoint = 1.0,
        space = "Lab",
        na.value = "grey90",
        guide = "colourbar",
        aesthetics = "fill"
        )
    
    