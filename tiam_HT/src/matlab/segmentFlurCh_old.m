function [IsegMask, fragmented, segmented]=segmentFlurCh_old(Iflur, cellData, cellCt, whichFlurCh)
% mostly copied from get_flurInt in tcmat_forVivek

imgCenterX=floor(size(Iflur,2)/2)+1;
imgCenterY=floor(size(Iflur,1)/2)+1;
medianInt=median(Iflur(:)); %I(:) converts it to a column vector

fragmented=0; % 1 if pSMAC is broken (disregarded if whichFlurCh is not 2)
segmented=0; % 1 if segmentation was successful

if whichFlurCh==4 % reporter
    [threshLevel,seg] = triangleThreshSeg(Iflur);
else % cSMAC, pSMAC, costim    
    % gaussian blurring before otsu thresholding
    h = fspecial('gaussian', [5,5], 1.5); %  these parameters work well for cSMAC, pSMAC and costim
    Iblur=imfilter(Iflur,h,'replicate'); % both 'conv' and 'replicate' give the same results
    %Iblur=imgaussfilt(Iflur, 1.5); is supported from R2015a onwards (absent in R2014a)
    [threshLevel, seg] = otsu2class(Iblur); % decided not to use the parameter on quality of separation
end   
seg(seg~=2)=0;seg(seg==2)=1; % in seg, 2 is foreground, 1 is background and 0 is NaN
Ibw = logical(seg);

img=Ibw;
%img = imfill(Ibw,'holes'); % decided not to do imfill as I will use pSMAC related information
seD=strel('disk',1); % 3 worked well without imhmax;  1 worked reasonable with imhmax
img = imdilate(img, seD); %with gaussian blurring with larger sigma, there is no need for dilation
imgDist=bwdist(~img, 'euclidean'); 
imgDist=imhmax(imgDist, 2); % will suppress the maxima if lower than 1 and reduce other values by 1. 1 worked reasonably; without suppression you get oversegmentation
imgDist=-imgDist; % need to create catchment for watershed, hence -ve   
imgDist(~img)=-inf; % '~' inverts the image; sets zero values to negative infinity which ensures that the background doesn't get segmented by watershed
imgLabel=watershed(imgDist); 
%assigns 0 values to all the boundary pixels and positive integers (labels) to regions

stats=regionprops(imgLabel,'basic');
% the component/label with the largest area appears to be the 1st component, which is also the background;
% but at times the background is split into two components/labels

dist=zeros(size([stats.Area]));
for i=1:length(dist)
    dist(i)=pdist([stats(i).Centroid;imgCenterX,imgCenterY],'euclidean');
    % distance between the centroid of the object and center pixel of the cropped box
    % centroid of the background component also tends to be very close to center pixel of the box
end
%save('label','imgLabel', 'stats', 'dist', 'I', 'img');
        
count1=zeros(size([stats.Area])); % counts the number of background pixels in a component
overlap1=zeros(size([stats.Area])); % counts the fraction of background pixels in a component
count2=zeros(size([stats.Area])); % counts the number of pixels within the DIC-cell outline in a component
overlap2=zeros(size([stats.Area])); % counts the fraction of pixels within the DIC-cell outline in a component
for label=1:length([stats.Area])
    count1(label)=nnz(~img(imgLabel==label)); % counts the number of background pixels which also had the particular label after watershed.
    overlap1(label)=count1(label)/stats(label).Area;
    count2(label)=nnz(cellData(cellCt).dilCellMask(imgLabel==label));
    overlap2(label)=count2(label)/stats(label).Area;
end    
%display(overlap);

pickedComps=[];
if length(dist) == 1 %if there is only one component (background only) 
    IsegMask=zeros(size(Iflur,1),size(Iflur,2)); % black image of the same size
    return % returns control to invoking function
elseif length(dist) >= 2 % if there are two or more components, pick the foreground component based on multiple conditions
    [temp,index]=sort([stats.Area],'descend'); %sorts in the descending order of area
    % index holds the indices of the elements that were sorted 
    for i=1:length(dist) % consider the component based on larger area
        if overlap1(index(i))<0.1 && overlap2(index(i))>0.9 && mean2(Iflur(imgLabel==index(i))) > medianInt 
            % very low overlap with background, high overlap with cell mask, higher intensity than overall median and closer to the center of the cropped image 
            % removed the condition: && dist(index(i)) < mean([imgCenterX,imgCenterY])/1.5 
            pickedComps(end+1)=index(i);
        end
    end   
end

if isempty(pickedComps)
    IsegMask=zeros(size(Iflur,1),size(Iflur,2)); % black image of the same size
    return % returns control to invoking function
else 
    segmented=1;
    if whichFlurCh==2 && length(pickedComps)>1 % if it is pSMAC channel, which tends to have more than component due to broken pSMAC
    % and if there are more than one components
        for i=2:length(pickedComps)
            if stats(pickedComps(i)).Area > 0.25*stats(pickedComps(1)).Area
            % if the area (i.e. pixel count) is more than 30% of the first component.    
            % removed the condition stats(pickedComps(i)).Area > 0.02*size(Iflur,1)*size(Iflur,2) &&
                imgLabel(imgLabel==pickedComps(i)) = pickedComps(1); % assigns the label of the first picked component.
                fragmented=1;
            end        
        end
    end   
end

imgLabel(imgLabel~=pickedComps(1))=0; % set the rest to zero to make it a binary image
imgLabel(imgLabel~=0)=1; % have the binary image in 0 and 1 (instead of some other number that may vary from case to case).
IsegMask=logical(imgLabel); %imgLabel is for unknown reason 'double' and hence converted to logical

end