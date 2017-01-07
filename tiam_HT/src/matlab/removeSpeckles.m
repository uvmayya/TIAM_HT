function binImg=removeSpeckles(binImg)
% removes small speckles in an iterative way in the binary image
% why doesn't it work effectively:
% it could be that before the next round of erosion, the size is more than
% 10 pixels and it disappears completely after erosion, in which case it
% will remain in the original image. it would have been good to check on
% the size during erosion, for which I will have to write the code from
% scratch. 

seD=strel('disk',1);
Ie=binImg; % initialization
for i=0:2
    CC=bwconncomp(Ie);
    if CC.NumObjects==0
        disp('no segments to even consider removing speckles');
        return
    end    
    for comp=1:CC.NumObjects 
        ccImg=zeros(size(binImg)); % blank image to put the speckles
        if numel(CC.PixelIdxList{comp})<=10 % if a small speckle
            ccImg(CC.PixelIdxList{comp})=1; % copy the speckle on to the blank image
            ccImg=logical(ccImg);
            for j=0:i
                if j>0, ccImg=imdilate(ccImg,seD); end % dilate the speckle back to original size
            end
            binImg(ccImg)=0; % assign the speckle pixels to zero in the original image
        end
    end   
    Ie=imerode(Ie,seD);        
%fprintf('cell %d component %d size %d\n', j, i,numel(CC.PixelIdxList{i}));                       
end
binImg=logical(binImg);
    
end    

