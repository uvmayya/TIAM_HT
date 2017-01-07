function [IsegMask, segmented, fragmented]=segmentFlurCh_v1(Iflur, cellData, cellCt, whichFlurCh, compLimit)
% based on _old, but with several modifications/improvements
% these are: thresholded segments used only if separation is good. 
% triangle thresholding for reporter is done only is otsu separation for it is good
% no need to use overlap with background as a criterion in segment picking since binary image is the input for regionprops
% reinstated the additional criteria picking segments
% not doing watershed for removing parts of the segmented image
% to handle speckles in pSMAC channel: doing thresholding without blurring,
% removing small objects and then blurring in conv2 for 2nd round of thresholding

% default params if not specified
if nargin==4
    compLimit=1; % means there is a limit on the number of components picked (only the first component is choosen)
elseif nargin<4
    disp('dont have all the input parameters');
    return %not doing any calculations
end   

imgCenterX=floor(size(Iflur,2)/2)+1;
imgCenterY=floor(size(Iflur,1)/2)+1;
medianInt=median(Iflur(:)); %I(:) converts it to a column vector

fragmented=0; % 1 if pSMAC is fragmented (disregarded if whichFlurCh is not 2)
segmented=0; % 1 if segmentation was successful

% gaussian blurring before otsu thresholding
h = fspecial('gaussian', [5,5], 1.5); %  these parameters work well for cSMAC, pSMAC and costim
Iblur=imfilter(Iflur,h,'replicate'); % both 'conv' and 'replicate' give the same results
%Iblur=imgaussfilt(Iflur, 1.5); is supported from R2015a onwards (absent in R2014a)
[threshLevel, seg, sep] = otsu2class(Iblur);
if whichFlurCh==2 && sep>=0.3 % for pSMAC
    [threshLevel, seg] = otsu2class(Iflur); % do otsu on the original image
    seg(seg~=2)=0;seg(seg==2)=1;
    CC=bwconncomp(seg);
    for comp=1:CC.NumObjects
        if numel(CC.PixelIdxList{comp})<=20 % if a small speckle of 20 pixels
            seg(CC.PixelIdxList{comp})=0; % remove the speckle
        end
    end    
    seg=single(seg);
    seg=conv2(seg,ones(4),'same'); % has blurring effect and gives the nearly the same outline as thresholding after gaussing blurring of the original image
    [threshLevel, seg] = otsu2class(seg);
    seg(seg~=2)=0;seg(seg==2)=1; % in seg, 2 is foreground, 1 is background and 0 is NaN    
elseif whichFlurCh==4 && sep>=0.3 % reporter
    [threshLevel,seg] = triangleThreshSeg(Iflur); % do triangle tresholding for reporter only if otsu thresholdign is good
    seg(seg~=2)=0;seg(seg==2)=1; % in seg, 2 is foreground, 1 is background and 0 is NaN    
elseif (whichFlurCh==1 || whichFlurCh==3) && sep>=0.3
    seg(seg~=2)=0;seg(seg==2)=1; % in seg, 2 is foreground, 1 is background and 0 is NaN    
else
    IsegMask=zeros(size(Iflur)); % black image of the same size
    %seg=zeros(size(Iflur)); % if not returning the control to invoking function
    return % returns control to invoking function
end

img = logical(seg);
%if whichFlurCh==2, img=removeSpeckles(img); end % the function doesn't work as effectively as I had thought
%img = imfill(Ibw,'holes'); % decided not to do imfill as this will destroy pSMAC
%this is the place to invoke watershed if needed, which also returns a binary image
imgLabel=bwlabel(img);

stats=regionprops(imgLabel,'basic'); % 

dist=zeros(size([stats.Area]));
for i=1:length(dist)
    dist(i)=pdist([stats(i).Centroid;imgCenterX,imgCenterY],'euclidean');
    % distance between the centroid of the object and center pixel of the cropped box
    % centroid of the background component also tends to be very close to center pixel of the box
end
%save('label','imgLabel', 'stats', 'dist', 'I', 'img');
        
count=zeros(size([stats.Area])); % counts the number of pixels within the DIC-cell outline in a component
overlap=zeros(size([stats.Area])); % counts the fraction of pixels within the DIC-cell outline in a component
for label=1:length([stats.Area])
    count(label)=nnz(cellData(cellCt).dilCellMask(imgLabel==label));
    overlap(label)=count(label)/stats(label).Area;
end    
%display(overlap);

pickedComps=[];
if length(dist) >= 1 % if there are one or more components, pick the foreground component based on multiple conditions
    [temp,index]=sort([stats.Area],'descend'); %sorts in the descending order of area
    % index holds the indices of the elements that were sorted 
    for i=1:length(dist) % consider the component based on larger area
        if stats(index(i)).Area > 0.02*size(Iflur,1)*size(Iflur,2) && overlap(index(i))>0.7 && mean2(Iflur(imgLabel==index(i))) > 1.2*medianInt  && dist(index(i)) < mean([imgCenterX,imgCenterY])/1.6 
            % high overlap with cell mask, higher intensity than overall median and closer to the center of the cropped image 
            pickedComps(end+1)=index(i);
        end
    end   
end

if isempty(pickedComps)
    IsegMask=zeros(size(Iflur)); % black image of the same size
    return % returns control to invoking function
else 
    segmented=1;
    if whichFlurCh==2 && length(pickedComps)>1 && compLimit==0 % if considering multiple components as fragments of discontinuous pSMAC
        for i=2:length(pickedComps)
            if stats(pickedComps(i)).Area > 0.015*size(Iflur,1)*size(Iflur,2) && stats(pickedComps(i)).Area > 0.2*stats(pickedComps(1)).Area
            % if the area (i.e. pixel count) is more than 1.5% of the total area and 20% of the first component ( at leat 20-30 pixels)
            % removed the condition: ?
                imgLabel(imgLabel==pickedComps(i)) = pickedComps(1); % assigns the label of the first picked component.
                fragmented=1;
            end        
        end
    end 
    imgLabel(imgLabel~=pickedComps(1))=0; % set the rest to zero to make it a binary image
    imgLabel(imgLabel~=0)=1; % have the binary image in 0 and 1 (instead of some other number that may vary from case to case).
    IsegMask=logical(imgLabel); %imgLabel is for unknown reason 'double' and hence converted to logical
end

end