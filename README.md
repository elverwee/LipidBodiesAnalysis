# LipidBodiesAnalysis

Scripts used for visualisation and analysis of lipid bodies within microalgal cells.
Microalgae analysed with Raman microsopy ==> Folder Raman analysis
Microalgae analysed with confocal laser scanning microscopy (CLSM) with spectral detector, after labelling with Nile Red ==> Folder Fiji analysis


1) Folder: Raman analysis
Script made in RStudio.
Input file(s): .spc file of one large area scan containing single spectra for each pixel with x and y coördinates

Script contains 3 parts: A, B, C
A) Basic raman data treatment with loading packages, retrieve large area scan characteristics from the file titles,
wavenumber selection, background subtraction, normalisation.
Combine all normalised large area scans within one hyperspec file.

B) Cluster the each large area scan to split between cell and background signal

C) Examples for plotting, to visualise the lipid bodies within the cell cluster.  


2) Folder: Fiji Analysis
   Scripts made in ImageJ
   Besides, program Ilastik was used for recognition of cells of lipid bodies in images

   File exported from microscope: .nd2 file of a Z-stack after spectral unmixing, containing 1 neutral lipids channel, 1 polar lipids channel, 1 pigment channel, 1 remaineder channel   and a channel with the transmission image

A) Create stack for lipid body mask.
Goal: Create Z-projections and combine all neutral lipid channels from the .nd2 files to use them in Ilastik for lipid body recognition
Input file: unmixed .nd2 files
Output: .tiff stack file containing all neutral lipid channels so that this file can be used in Ilastik for lipid body recognition. 

Output file from Ilastik = one .tiff for each original .nd2 file with lipid bodies having pixel value of 1 = lipid body segmentation file

B) Create stack for cell mask.
Goal: Combine all 5 channels from the raw .tiff files to use them in Ilastik for cell recognition
Input file: raw .tiff file (which is unmixed .nd2 file of which a Z-projection had been made and saved as .tiff)
Output: .h5 (HDF5) stack file containing all five channels so that this file can be used in Ilastik for cell recognition. 

Output file from Ilastik = one .tiff for each original .nd2 file with cells having pixel value of 1 = cell segmentation file

C) Create cell labels
Goal: Recognise cells and create cell mask, based on the output file from Ilastik executed after part B. Additional lipid body analysis per cluster.
Touching cells will be recgonised as one cluster, and each cluster will get a different label. When cells are not touching, one cluster can also consist of one single cell. 
Input files: 1) raw .tiff files (see B)
        2) lipid body segmentation files (see A)
        3) cell segmentation files (see B)

Output: cell labels as .tiff files and .txt file with lipid body characteristics for each cluster. 

D) Goal: From the cell labels, retain living single cells only, and link the lipid bodies to their cell. Analysis of lipid body characteristics per cell: area, diameter, intensity, ...
Input files: 1) raw .tiff files (see B)
        2) lipid body segmentation files (see A)
        3) cell label files (see C)

Output: .txt file with lipid body characteristics for each single cell


   
