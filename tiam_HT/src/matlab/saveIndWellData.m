function saveIndWellData(cellData, pathToDir, expName)
% cellData has all data from all wells
% this function stores data for each well in a separate .mat file


%make a or prepare the pre-existing sub-folder under ws/ to store all .mat files
resultFolder=[pathToDir,'ws/',expName,'_perWell'];
if exist(resultFolder,'dir')==7  % 7 means the directory exists
    delete([resultFolder,'/','*.mat']); %delete all existing tif files
else    
    mkdir(resultFolder); 
end  

wellList={cellData.well};
uniqWells=unique(wellList); % a row cell-array of strings

for i=1:length(uniqWells)
    cellDataPerWell=cellData(strcmp(wellList,uniqWells{i})); % extracts all fields that belong to the relevant cell
    resultsFile=[resultFolder,'/',uniqWells{i},'_results.mat'];
    save(resultsFile,'cellDataPerWell'); 
    clear cellDataPerWell; % remove it after saving
end

end