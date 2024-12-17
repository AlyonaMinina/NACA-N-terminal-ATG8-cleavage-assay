# NACA, N-terminal ATG8 cleavage assay 
## (In the standard layout, this assay is commonly known as the GFP-cleavage assay. However it can be performed on ATG8 harboring other detectable N-terminal tags)


ImageJ macro for densitometric analysis of Western blots for GFP-cleavage assay. 
<br>
 
</br>
This ImageJ macro is written for analysis to be performed directly on the raw files from the Bio-Rad ChemiDoc (".scn") or on .tiff files.
<br>
 
</br>
Macro will:
- analyze ALL images within user-selected folder
- save rotated/cropped images of western blots
- save ROIs selected for analysis for each image. Those can be double-checked after analysis
- for each image, subtract the corresponding background signal from the raw integrated density of Tag-ATG8 and free Tag bands
- for each sample calculate integrated density of the free Tag band as % of cumulative Tag signal detected in the sample
- save quantitative data for all analyzed images into a single .csv file
<br>
 
</br>

The example in the video shows analysis performed on three images of the same WB to obtain three technical replicates of the measurement:
1. WB image files were checked to not contain oversaturated pixels
2. Images applicable for analysis were placed into a dedicated folder
3. Download and unzip the repository folder -> drag and drop macro file into ImageJ menu bar
4. Follow the instructions provided by the macro
5. You can check the position of the ROIs on your image and rerun the analysis if they are not placed correctly
6. Depending on the number of analyzed images and complexity of the experiment layout, quantitative data from .csv files can be processed using R or Excel.

<p align="center"> <a href="https://youtu.be/zbv4CxE57vA"><img src="https://github.com/AlyonaMinina/GFP-cleavage-assay/blob/main/Images/GFP-cleavage%20assay%20preview.PNG" width = 480> </img></a></p>



