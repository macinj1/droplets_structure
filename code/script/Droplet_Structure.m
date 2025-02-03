function [setting,image,BWI,droplet,void,void_topology,Radio,CV,DT,grain_boundaries,grain_size,inner_angles_distribution,psi] = Droplet_Structure % (setting)

%% Read an image
disp('Select your Image file.... The file selected is:')
[filename, pathname] = uigetfile({'*.tiff';'*.jpg';'*.png';'*.tif'}, 'Select a Image file');
FileName = fullfile(pathname,filename);
image = imread(FileName) ; 
disp(filename)

setting.filename = filename ; 
setting.pathname = pathname ; 
clear filename pathname FileName

%% Rotate image: 
% Select 2 points over the SAME edge of the channel:
disp(' ')
disp('Select 2 points over the SAME edge of the chamber:')
imshow(image)
title('Select 2 points over the SAME edge of the chamber:')
 
[X,Y] = ginput(2);
angle = ( atan( (Y(2) - Y(1)) / (X(2) - X(1)) ) )*180/pi ; 
image = rotateAround( image , X(1), X(2), angle ) ; 
imshow(image)
title('Image rotated')
pause(2)
setting.rotationCenter = [X(1) X(2)];

%% Selecting the area to analyse

disp(' ')
prompt = "Do you want to draw the area of interest? y/n: ";
txt = input(prompt,"s");

if strcmp(txt,'y')
    
    disp(' ')
    disp('Then, Draw the area of interest, right click, and select "Crop Image":')
    [I,CroppedSection] = imcrop(image) ; 

else
    
    disp(' ')
    disp('Then, add manually the area of interest: ')
    prompt = "What it the x-coordinate of upper left corner? ";
    x = input(prompt);
    prompt = "What it the y-coordinate of upper left corner? ";
    y = input(prompt);
    prompt = "What it the width of your box? ";
    w = input(prompt);
    prompt = "What it the height of your box? ";
    h = input(prompt);

    CroppedSection = [x y w h] ;

    [I] = imcrop(image,CroppedSection) ; 

end

BW = imextendedmax( imcomplement( rgb2gray( I ) ) , 70 ) ; 
imshow(BW)
title('Selected area')
pause(2)
close all
setting.CroppedSection = CroppedSection ; 
clear CroppedSection

%% Find all the objects in the image

BWI = bwareaopen(~BW,500) ; 
[~,L] = bwboundaries(BWI,'noholes');
stats = regionprops(L,'ConvexHull','Centroid','Area');

B = cell(length(stats),1) ; 
for k = 1:length(stats)

    B{k,1} = stats(k).ConvexHull ; 
    
end

setting.Number_Objects = length(stats) ; 

%% Classify objects: droplet or void

droplet = [] ; 
void = [] ;

idx = [] ; 
idxb = [] ; 

Marea = mean( cat(1,stats.Area) ) ; 

for i = 1:length(B)

    a = polyarea( B{i}(:,1) - mean( B{i}(:,1) ) , B{i}(:,2) - mean( B{i}(:,2) ) ) ;

    if stats(i).Area / a > 0.9 && stats(i).Area > 0.1*Marea

        droplet = [ droplet ; stats(i).Centroid ] ; 
        idx = [idx ; i ] ; 

    else

        void = [ void ; stats(i).Centroid ] ; 
        idxb = [idxb ; i ] ; 

    end

end

setting.Number_Droplets = length(idx) ; 
setting.Number_Voids = length(idxb) ; 

%% Void Topology 

void_topology = zeros(length(idxb),1) ;

for i = 1:length(idxb)

    s = [ diff( B{idxb(i)}(:,1) - mean(B{idxb(i)}(:,1)) ).^2 + diff( B{idxb(i)}(:,2) - mean(B{idxb(i)}(:,2)) ).^2 ; 0 ] ; 
    void_topology(i,1) = [ sum(s>50) ] ;

end

%% Coefficient of variation (CV) base on monodispersity

area_droplet = cat(1,stats(idx).Area) ; 
Radio = sqrt(area_droplet/pi) ; 
CV = std(Radio) / mean(Radio) ;

%% Crystal and Grain 

DT = delaunayTriangulation(droplet) ; 

regular = zeros(length(DT.ConnectivityList),7) ; 

for j = 1:length(DT.ConnectivityList)

    angle_aux = [] ; 

    for k = 1:3

        V = diff( DT.Points( circshift( DT.ConnectivityList(j,:) , k ) , : ) ) ; 

        angle_aux = [angle_aux 180 - acosd( dot( V(1,:) , V(2,:) ) / ( norm(V(1,:)) * norm(V(2,:)) ) ) ] ; 

    end 

    D = pdist2( DT.Points( DT.ConnectivityList(j,:) , : ) , DT.Points( DT.ConnectivityList(j,:) , : ) ) ;

    regular(j,1:6) = [ D(2,1) D(3,1) D(2,3) angle_aux ] ; 

end

for j = 1:length(regular)

    regular(j,7) = all( [ abs( regular(j,1:3) - mean( regular(j,1:3) ) ) < 20  abs( regular(j,4:6) - 60 ) < 5 ] ) ; 

end

grain_boundaries = zeros(size(I,[1 2])) ; 

for k = 1:length(DT.ConnectivityList)

    if regular(k,7)

        bw = poly2mask( DT.Points( DT.ConnectivityList(k,:) , 1 ) , DT.Points( DT.ConnectivityList(k,:) , 2 ) , size(I,1) , size(I,2) ) ; 
    
        grain_boundaries = grain_boundaries + bw ; 

    end

end

CC = bwconncomp(grain_boundaries) ; 

for k = 1:CC.NumObjects

    grain_size(k,1) = length(CC.PixelIdxList{k}) ; 

end

inner_angles_distribution = reshape( regular(:,4:6) , [size(regular,1)*3 1] ) ; 

%% Local bond orientation

edges = [] ; 

for k = 1:length(DT.ConnectivityList)

    conn_aux = [ DT.ConnectivityList(k,1) DT.ConnectivityList(k,2) ; DT.ConnectivityList(k,1) DT.ConnectivityList(k,3) ; DT.ConnectivityList(k,2) DT.ConnectivityList(k,3) ] ; 

    edges = [ edges ; conn_aux ] ; 

end

for k = 1:length(edges)

    contact = pdist2( droplet( edges(k,1) , : ) , droplet( edges(k,2) , : ) ) - sum( Radio( edges(k,:) ) ) ; 

    if contact > 50 

        edges(k,:) = [0 0] ; 

    end

end

edges( edges(:,1) == 0 , : ) = [] ; 

%% Calculate psi_6 

psi = zeros(length(droplet), 1);

for k = 1:length(droplet)

    clear V 

    V = [ droplet( edges( edges(:,2) == k , 1 ) , : ) ; droplet( edges( edges(:,1) == k , 2 ) , : ) ] -  droplet(k,:) ; 

    psi_aux = 0 ;

    for j = 1:size(V,1)

        psi_aux = psi_aux + exp( 6*1i*acos( dot( [1 0] , V(j,:) ) / norm( V(j,:) ) ) ) ; 

    end

    if size(V,1) ~= 0

        psi(k,1) = abs(psi_aux) / size(V,1) ; 

    else

        psi(k,1) = 0 ; 

    end

end

%% Clean matrix

close all 
disp(' ')
disp('Analysis is done!')
