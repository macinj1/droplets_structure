# Droplet Structure Analysis: Crystallography approach

This code analyses figures or videos containinig group of bubbles and 
provides for each a different data struture base on your selection. Set
the "file_type" variable and click run. 

For figures, the code analyses each object, droplet or void, and provides the following outputs:
   - setting: all the parameter used; 
   - image: the rotated image used for the analyses; 
   - BW: the final filtered image; 
   - droplet: droplet (x,y) coordinates; 
   - void: voids (x,y) coordinates; 
   - void_topology: number of sides of each void; 
   - eq_radio: droplet monodispersity; 
   - CV: coefficient of variation based on droplet radius; 
   - grain_boundaries: image with grain location; 
   - grain_size: area in pixels of each grain. 


The image is rotated around a specific point using the function rotateAround [1].

[1] Jan Motl (2025). Rotate an image around a point (https://www.mathworks.com/matlabcentral/fileexchange/40469-rotate-an-image-around-a-point), MATLAB Central File Exchange. Retrieved February 3, 2025.
