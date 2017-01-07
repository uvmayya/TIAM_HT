function [meanVal,img] = getPerWellStatsFromMat(cellData,fieldName)
% this gives mean values per every image field in every well as a heat map in the 96-well plate format
% fieldName given as a string
% set the field organization for the heatmap in the code and make sure it is correct. 
% this function is used after the final cellData structure is created by tiamHT.
% assumes that entries are ordered (i.e. all entries for a particular well/field are together and follow a sequence)

% set these properly as per the dataset
pixelSize=10; % determines how many pixels represent one well mean value

val=cell(8,12); % 8 well rows and 12 well columns in the 96 well plate
meanVal=zeros(8,12);

% populate val
for cellCt = 1 : length([cellData.cellID])
    %disp(cellCt);
    well=cellData(cellCt).well;
    wellRow=uint8(well(1))-64; % 65 is the ASCII value of 'A'
    wellCol=str2num(well(2:end));
    
    if ~isempty(cellData(cellCt).(fieldName))
        val{wellRow,wellCol}(end+1)=cellData(cellCt).(fieldName); % passes the fieldName string as the fieldName variable if within brackets
    end    
end    

% calculate meanVal from val
for r=1:8
    for c=1:12
        meanVal(r,c)=mean(val{r,c});
    end
end

% create the image based on meanVal
% remember that y-axis is rows and x-axis is cols
imX=(12*pixelSize)+13;
imY=(8*pixelSize)+9;
img=zeros(imY,imX); 
yInd=1; % initialization
for r=1:8
    yInd=yInd+1; % to have a blank entry to demarcate beginning of a new well
    xInd=1; % initialization for every column
    for c=1:12
        xInd=xInd+1; % to have a blank entry to demarcate beginning of a new well  
        img(yInd:yInd+pixelSize-1,xInd:xInd+pixelSize-1)=meanVal(r,c);
        xInd=xInd+pixelSize;        
    end
    yInd=yInd+pixelSize;
end
img=uint16(img); 
% theoretically imwrite is supposed to transform it between 0 and 1 and then apply 8-bit scaling. 
% but it is not working hence the uint16 conversion to maintain the original values as much as possible. 
imwrite(img,[fieldName,'.tif'],'tif','Compression', 'none');


end

