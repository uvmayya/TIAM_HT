function cellData = getOutline(cellData, videocell, halfCropSize, detectParams, pathToDir, expName)

% this function adds additional information () and gives a tiff-series with outlines drawn on transmitted light images.

tic

for frame = 1 : size(videocell, 2)
    outlineVideo{frame}=videocell{frame}; 
    % have outlineVideo onto which outlines will be drawn and updated for every cell, which keeps the original videocell without any manipulation.
end    

for cellCt = 1 : length([cellData.cellID])
    frame = cellData(cellCt).frame;
    center_x = round(cellData(cellCt).CHTcenterX); % rounded to nearest integer
    center_y = round(cellData(cellCt).CHTcenterY);
        
    halfcropXsize = halfCropSize; %size influences how watershed works (because the size determines the gradient)
    halfcropYsize = halfCropSize;
    if center_x<=halfcropXsize
        halfcropXsize=center_x-1;
    elseif center_x+halfcropXsize>=size(videocell{frame},2)
        halfcropXsize=size(videocell{frame},2)-center_x; % column value corresponds to x-coordinate of the pixel
    end % to account for centroids that are too close the edges of the frames
    if center_y<=halfcropYsize
        halfcropYsize=center_y-1;
    elseif center_y+halfcropYsize>=size(videocell{frame},1)
        halfcropYsize=size(videocell{frame},1)-center_y; % row value corresponds to y-coordinate of the pixel
    end % to account for centroids that are too close the edges of the frames

    if(length(size(videocell{1,frame})) == 3)
        I=rgb2gray(videocell{frame});
    else I=videocell{frame}; 
    end 

    %I = medfilt2(I,[2 2]); % median filtering of BF images from Operatta had help remove background granularity.
    I = imcrop(I, [uint16(center_x-halfcropXsize) uint16(center_y-halfcropYsize) halfcropXsize*2 halfcropYsize*2]);
    % the first pixel in the cropped image corresponds to center_y-halfcropsize and center_x-halfcropsize in the original image
    % actual size of the cropped image is twice the halfcropsize plus 1
    % thus centroid pixel(halfcropYsize+1,halfcropXsize+1) is the absolute center pixel and there are equal number of pixels on all sides
    % unit16 converts to unsigned 16-bit integer type
        
    [Ie,thresh] = edge(I,'canny'); %[temp,thresh] = edge(Ifilt,'canny');
    %Ie = edge(I, 'canny', 0.7*thresh, 0.8); %0.7*thresh for exp1, 1.3*thresh for exp5
    Ie = edge(I, 'canny', 1.0*thresh, 2.2); % 1.3*thresh for exp5;1.3,1.2
    %Ie = edge(I, 'canny', 1.1*thresh, 0.8); % earlier
    %Ie=edge(I, 'canny', detectParams(2), 0.8); % using the input edge value didn't work
    Icht = im2uint8(Ie); % needed for CircularHough_Grd function
            
    % structural elements
    se90 = strel('line', 3, 90);
    se0 = strel('line', 3, 0);
    disk3 = strel('disk', 3); % 4/3 for exp1 and 3 for exp5; 4/3 worked well overall and didn't cause cells to merge after dilation
    disk2 = strel('disk', 2);

    % take canny image and dilate, fill, erode, and dilate
    Id = imdilate(Ie, [se90, se0]);
    If = imfill(Id, 'holes');
    Ir = imerode(If, disk3);
    img = imdilate(Ir, disk2);
    centerBlob = imerode(img, disk2);
            
    % circular hough transform
    %[accum, circen, cirrad] = CircularHough_Grd(test, [rad_min rad_max], gradientThresh, searchRadius);  % function call format
    accum=CircularHough_Grd(Icht, [round(detectParams(3)/detectParams(1)) round(detectParams(4)/detectParams(1))], detectParams(5), detectParams(6)); % [7 15]
    %accum1=imhmax(accum,300); % 1000 appeared to worked well; 
    %ultimately I didn't need to suppress local maxima as there was no difference with and without suppression 
    imgDist=imimposemin(-accum,centerBlob); % forces the minimum to be on the centerBlob
        
    imgDist(~img)=-inf; % '~' inverts the image; sets zero values to negative infinity which ensures that the background doesn't get segmented by watershed
    imgLabel=watershed(imgDist);
    %watershed assigns 0 values to all the boundary pixels and positive integers (labels) to regions
    
    % earlier I was using a different approach to handle background, which I have discarded
    %imgLabel=watershed(imgDist)>0; 
    % but by having '>0' only non-zero values are stored in imgLabel.
    % This allows me to do the .* operation (because of compatible data-type) later on so that I can use bwlabel function. This will eliminate the need to handle background as a component.
    %bwLabel=img.*imgLabel; % removes background component(s)
    %imgLabel=bwlabel(bwLabel);
        
    stats=regionprops(imgLabel,'Area', 'Centroid', 'Eccentricity', 'MajorAxisLength', 'MinorAxisLength', 'Perimeter'); % 'basic'; 'Area', 'BoundingBox', 'Centroid', 'Eccentricity', 'MajorAxisLength', 'MinorAxisLength', 'Perimeter');
    % the component/label with the largest area appears to be the 1st component, which is also the background;
    % but at times the background is split into two components/labels

    dist=zeros(size([stats.Area]));
    for i=1:length(dist)
        dist(i)=pdist([stats(i).Centroid;halfcropXsize+1,halfcropYsize+1],'euclidean');
        % distance between the centroid of the object and center pixel of the cropped box
        % centroid of the background component also tends to be very close to center pixel of the box
    end
    %save('label','imgLabel', 'stats', 'dist', 'I', 'img');
    
    count=zeros(size([stats.Area])); % counts the number of background pixels in a component
    overlap=zeros(size([stats.Area])); % counts the fraction of background pixels in a component
    for label=1:length([stats.Area])
        count(label)=nnz(~img(imgLabel==label)); % counts the number of background pixels which also had the particular label after watershed.
        overlap(label)=count(label)/stats(label).Area;
    end    
    
    boundary=zeros(size(I));
    cellData(cellCt).hasInfo=0;
    %if length(dist) == 1 %if there is only one component (background only) pick it
    if length(dist) >= 2 % if there are two or more components, pick the foreground component that is closest to the center pixel of the cropped box
        [temp,index]=sort([stats.Area], 'descend'); %sorts in the descending order of area
        % index holds the indices of the elements that were sorted 
        for i=1:length(dist) % to pick based on proximity to the center of the cropped image
            circularity=(4*pi*stats(index(i)).Area)/(stats(index(i)).Perimeter)^2; 
            % circularity is 1 for circle and 0 for line; Eccentricity is 0 for circle and 1 for line;
            if overlap(index(i))<0.1 && dist(index(i)) < mean([halfcropXsize+1,halfcropYsize+1])/1.5 && stats(index(i)).Area > 0.1*size(I,1)*size(I,2) && stats(index(i)).Eccentricity<0.8 && circularity>0.3 
                % little overap with the background, closer to the center of the cropped image & of a decent size & approximates a circular like shape  
                cellData(cellCt).hasInfo=1;
                cellData(cellCt).massCentroid=stats(index(i)).Centroid;
                cellData(cellCt).area=stats(index(i)).Area;
                cellData(cellCt).eccentricity=stats(index(i)).Eccentricity;
                cellData(cellCt).circularity=circularity;
                cellData(cellCt).polarity=stats(index(i)).MajorAxisLength/stats(index(i)).MinorAxisLength;
                
                % storing boundary information
                imgLabel(imgLabel~=index(i))=0; % set the rest to zero to make it a binary image
                imgLabel(imgLabel~=0)=1; % have the binary image in 0 and 1 (instead of some other number that may vary from case to case).
                boundary=bwperim(imgLabel,8);
                                
                % create cropped tiff files of the DIC image of the cell and the cell boundary
                %well=cellData(cellCt).well;
                %if exist([pathToDir,'ws/',expName,'/',well],'dir')~=7 % doesn't exist
                %    mkdir([pathToDir,'ws/',expName],well);
                %end
                %imwrite(boundary,[pathToDir,'ws/',expName,'/',well,'/',int2str(cellCt),'_boundary.tif'],'tiff','Compression','none');
                %imwrite(I,[pathToDir,'ws/',expName,'/',well,'/',int2str(cellCt),'_transLight.tif'],'tiff','Compression','none');
                    
                imgLabel=logical(imgLabel); %imgLabel is for unknown reason 'double' and hence converted to logical
                dilImgLabel1=imdilate(imgLabel,strel('disk',2));
                %dilBoundary1=bwperim(dilImgLabel1,8);
                dilImgLabel2=imdilate(dilImgLabel1,strel('disk',2)); %dilate again for background
                %dilBoundary2=bwperim(dilImgLabel2,8);
                dilImgLabel2(dilImgLabel1==1)=0; % will keep the rim pixels for background
                cellData(cellCt).cellImg=I;
                cellData(cellCt).cellMask=imgLabel;
                cellData(cellCt).dilCellMask=dilImgLabel1;
                cellData(cellCt).bgMask=dilImgLabel2;
                                
                I(boundary==1) = 0; % the pixels identified as boundary pixels (value 1) in 'boundary' are set to 0 in I giving a black outline
                outlineVideo{frame}(uint16(center_y-halfcropYsize):uint16(center_y+halfcropYsize), uint16(center_x-halfcropXsize):uint16(center_x+halfcropXsize))=I;
                break
            end
        end
    end
    
    % only if all detection events need to be stored
    %imwrite(boundary,[pathToDir,'ws/',expName,'/',int2str(cellCt),'_boundary.tif'],'tiff','Compression','none');
    %imwrite(I,[pathToDir,'ws/',expName,'/',int2str(cellCt),'_transLight.tif'],'tiff','Compression','none');
               
    % display information
	%fprintf('Outline calculation complete for cell-ID: %d\n', cellCt);
    
end    

% write the images with outline to a tiff-sereis file
%tiffFileName = [pathToDir,'ws/', expName,'_outline.tif'];
%I=outlineVideo{1};
%imwrite(I,tiffFileName);
%for frame = 2 : size(outlineVideo, 2)
%    I=outlineVideo{frame};
%    imwrite(I,tiffFileName,'WriteMode','append'); % append images into a tiff-series file
%end

disp('Outline calculation complete for all cells');

toc