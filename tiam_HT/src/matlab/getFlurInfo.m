function cellData = getFlurInfo(cellData,videocell,halfCropSize,cellCt,whichFlurCh,compLimit)
% this function returns fluorescence data from channel whichFlurChannel within the footprint of each cell.

% default params if not specified
%if nargin<4
if nargin==5
    compLimit=1; % means there is a limit on the number of components picked (only the first component is choosen)
elseif nargin<5
    disp('dont have all the input parameters');
    return %not doing any calculations
end    

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
    Iflur=rgb2gray(videocell{frame});
else Iflur=videocell{frame};
end 

Iflur = imcrop(Iflur, [uint16(center_x-halfcropXsize) uint16(center_y-halfcropYsize) halfcropXsize*2 halfcropYsize*2]);
% the first pixel in the cropped image corresponds to center_y-halfcropsize and center_x-halfcropsize in the original image
% actual size of the cropped image is twice the halfcropsize plus 1
% thus centroid pixel(halfcropYsize+1,halfcropXsize+1) is the absolute center pixel and there are equal number of pixels on all sides
% unit16 converts to unsigned 16-bit integer type

[IsegMask, segmented, fragmented]=segmentFlurCh_v1(Iflur, cellData, cellCt, whichFlurCh, compLimit);

% flur related info: int, area, weighted centroid, outline/mask, image
if whichFlurCh==1 % cSMAC
    cellData(cellCt).flur1_hasInfo=segmented;
    cellData(cellCt).flur1_img=Iflur;
    cellData(cellCt).flur1_mask=IsegMask; 
    %boundary=bwperim(IsegMask,8); decided not to store boundary as mask is stored
    if segmented==1
        cellData(cellCt).flur1_area=nnz(IsegMask);
    
        meanInt=mean(Iflur(IsegMask)); % Iflur(IsegMask) is a vector and hence mean2 is not needed and mean fn is sufficient 
        bgPixels=Iflur(cellData(cellCt).bgMask); % vector of background pixel intensities
        percentile80=prctile(bgPixels,80); 
        outlierIndices=bgPixels>percentile80 & bgPixels>3*median(bgPixels); % & is AND operator for vector
        bgPixels(outlierIndices)=[]; % removes outlier pixel intensities;
        meanInt=meanInt-mean(bgPixels); % background corrected mean intensity
        cellData(cellCt).flur1_int=meanInt;
    
        %getting weighted centroid, which only works for single component image
        stats=regionprops(IsegMask,Iflur,'WeightedCentroid');
        cellData(cellCt).flur1_wtCentroid=stats(1).WeightedCentroid;    
    end
elseif whichFlurCh==2 %pSMAC
    cellData(cellCt).flur2_hasInfo=segmented;
    cellData(cellCt).flur2_img=Iflur;
    cellData(cellCt).flur2_mask=IsegMask;
    if segmented==1
        cellData(cellCt).flur2_broken=1; % initialization
        cellData(cellCt).flur2_fragmented=fragmented;   
        cellData(cellCt).flur2_area=nnz(IsegMask);
            
        meanInt=mean(Iflur(IsegMask)); % Iflur(IsegMask) is a vector and hence mean2 is not needed and mean fn is sufficient 
        bgPixels=Iflur(cellData(cellCt).bgMask); % vector of background pixel intensities
        percentile80=prctile(bgPixels,80); 
        outlierIndices=bgPixels>percentile80 & bgPixels>3*median(bgPixels); % & is AND operator for vector
        bgPixels(outlierIndices)=[]; % removes outlier pixel intensities;
        meanInt=meanInt-mean(bgPixels); % background corrected mean intensity
        cellData(cellCt).flur2_int=meanInt;
    
        if fragmented==0                   
            stats=regionprops(IsegMask,Iflur,'WeightedCentroid', 'Perimeter', 'Area'); % this only works for single component image
            cellData(cellCt).flur2_wtCentroid=stats(1).WeightedCentroid;
            
            pSMACfill = imfill(IsegMask,'holes');
            if nnz(pSMACfill) > nnz(IsegMask)
                cellData(cellCt).flur2_broken=0; % if there is a hole in the middle then pSMAC is intact
            else
                % using circularity works better than bwconvhull to decide on pSMAC status
                circ=(4*pi*stats(1).Area)/(stats(1).Perimeter)^2;  % concave part 
                % circularity is 1 for circle and 0 for line and is less than 0.7 if there is a dominant concave part to the boundary
                if circ<0.7, cellData(cellCt).flur2_broken=1; % in broken pSMACs the inner outline is concave
                else cellData(cellCt).flur2_broken=2; % more likely a pSMAC with no central hole
                end    
            end    
        else % fragmented pSMAC 
            cellData(cellCt).flur2_broken=1; % multi-component fragmented pSMAC is also a broken pSMAC. 
            
            % combine info from all components
            stats=regionprops(IsegMask,Iflur,'PixelIdxList', 'PixelList');
            pixelVals=[]; pixelCoords=[];
            for i=1:numel(stats)
                % catenate all pixel ids and 
                intenVals=double(Iflur(stats(i).PixelIdxList));% vector of all relevant pixel intensity values; double for scalar multiplication later
                pixelVals=cat(1,pixelVals,intenVals);
                pixelCoords=cat(1,pixelCoords,stats(i).PixelList);
            end
            x=pixelCoords(:,1); y=pixelCoords(:,2);
            xbar=sum(x.*pixelVals)/sum(pixelVals); %int. weighted centroids (.* needs integers of the same class or scalar doubles)
            ybar=sum(y.*pixelVals)/sum(pixelVals); %int. weighted centroids
            cellData(cellCt).flur2_wtCentroid=[xbar,ybar];
        end    
    end
elseif whichFlurCh==3 % costim   
    cellData(cellCt).flur3_hasInfo=segmented;
    cellData(cellCt).flur3_img=Iflur;
    cellData(cellCt).flur3_mask=IsegMask;
    if segmented==1
        cellData(cellCt).flur3_area=nnz(IsegMask);
    
        meanInt=mean(Iflur(IsegMask)); % Iflur(IsegMask) is a vector and hence mean2 is not needed and mean fn is sufficient 
        bgPixels=Iflur(cellData(cellCt).bgMask); % vector of background pixel intensities
        percentile80=prctile(bgPixels,80); 
        outlierIndices=bgPixels>percentile80 & bgPixels>3*median(bgPixels);  % & is AND operator for vector
        bgPixels(outlierIndices)=[]; % removes outlier pixel intensities;
        meanInt=meanInt-mean(bgPixels); % background corrected mean intensity
        cellData(cellCt).flur3_int=meanInt;
    
        %getting weighted centroid, which only works for single component image
        stats=regionprops(IsegMask,Iflur,'WeightedCentroid');
        cellData(cellCt).flur3_wtCentroid=stats(1).WeightedCentroid;    
    end
elseif whichFlurCh==4 % reporter
    cellData(cellCt).flur4_hasInfo=segmented;
    cellData(cellCt).flur4_img=Iflur;
    cellData(cellCt).flur4_mask=IsegMask;
    if segmented==1
        cellData(cellCt).flur4_area=nnz(IsegMask);
    
        meanInt=mean(Iflur(IsegMask)); % Iflur(IsegMask) is a vector and hence mean2 is not needed and mean fn is sufficient 
        bgPixels=Iflur(cellData(cellCt).bgMask); % vector of background pixel intensities
        percentile80=prctile(bgPixels,80); 
        outlierIndices=bgPixels>percentile80 & bgPixels>3*median(bgPixels); % & is AND operator for vector
        bgPixels(outlierIndices)=[]; % removes outlier pixel intensities;
        meanInt=meanInt-mean(bgPixels); % background corrected mean intensity
        cellData(cellCt).flur4_int=meanInt;
    
        %getting weighted centroid, which only works for single component image
        stats=regionprops(IsegMask,Iflur,'WeightedCentroid');
        cellData(cellCt).flur4_wtCentroid=stats(1).WeightedCentroid;    
    end
end    
    
% display information
%fprintf('Flur ch %d calculation complete for cell-ID: %d\n', whichFlurCh, cellCt);


end

