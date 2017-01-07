function tiamHTbatchScript_afterPerm(batchSetupCell)

%nameLength = 28; % length of: src/matlab/tiamHTbatchScript
%pathToFn = mfilename('fullpath');
%pathToDir = pathToFn(1:end-nameLength);
pathToDir = 'F:/Salvo/synapseHTdata/';

for job=1:length(batchSetupCell)
    tic

    % Run general algorithm on all frames in video
    % --------------------------------------------

    % parse batchSetupCell
    jobSetup = batchSetupCell{job};
    expName = jobSetup{1};
    dirstring = jobSetup{2};
    maskImgPath = jobSetup{3};
    cyclesize = jobSetup{4};
    numimgs = jobSetup{5};
    % image order
    startimg = jobSetup{6};
    startimg_flur1 = jobSetup{7}; % cSMAC not included after permeablizatn
    startimg_flur2 = jobSetup{8}; % pSMAC not included after permeablizatn
    startimg_flur3 = jobSetup{9};
    startimg_flur4 = jobSetup{10}; 
    % detectParams
    detectParams = jobSetup{11};
    % size conversion and other specifications
    numUmPerPix_convert = jobSetup{12};
    halfCropSize = jobSetup{13};

 
    % reading images into videocell, videocell_flur1, videocell_flur2, and videocell_flur3
    % -----------------------------------------------------------------------------------

    disp('Loading transmitted light images...')
    [videocell,imgNames] = imgfolder2videocell(dirstring, startimg, cyclesize, numimgs);
    % irrelevant now: imgNames will keep getting updated with additional channels included. But since only the channel info changes, rest of the information on the image is intact and consistent.
    % irrelevant now: nonetheless the transmitted image series is loaded last so that imageNames holds those names.
    maskImage=imread(maskImgPath);
    %disp('All images from all channels loaded.')

    % cell detection
    disp('...Starting cell detection.')
    cellData = celldetect_batch(videocell, detectParams, maskImage, imgNames);

    %make a or prepare the pre-existing sub-folder under ws/ to store images of all cells
    %if exist([pathToDir,'ws/',expName],'dir')==7  % 7 means the directory exists
    %    rmdir([pathToDir,'ws/',expName,'/','*'],'s'); %removes all sub-folders and their contents
    %    delete([pathToDir,'ws/',expName,'/','*']); %delete all files
        %delete([pathToDir,'ws/',expName,'/','*.tif']); %delete all existing tif files
        %cellImages=dir([pathToDir,'ws/',expName,'/']);
        %for i=1:length([cellImages.isdir]);
        %    if strcmp(cellImages(i).name,'.') && strcmp(cellImages(i).name,'..')
        %        delete(cellImages(i).name);
        %    end
        %end
    %else    
    %    mkdir([pathToDir,'ws/'],expName); 
    %end    
    
    % outline & masks for individual cells from transmitted light image series
    cellData = getOutline(cellData, videocell, halfCropSize, detectParams, pathToDir, expName);
    
    % save matlab .mat file again (overwrites the previous .mat file written before)
    %timeSoFar = toc;
    resultsFile = [pathToDir,'ws/', expName,'_results.mat'];
    save(resultsFile,'cellData');
    disp(['Results of all detected cells saved as: ', resultsFile]);
    
    clear videocell; % to release occupied RAM as the stored variable is not needed further
    
    % fluorescence information for each available/requested channel
    %-----------------------------------
    if startimg_flur1>0, [videocell_flur1,imgNames] = imgfolder2videocell(dirstring, startimg_flur1, cyclesize, numimgs); end;
    if startimg_flur1>0 % cSMAC
        for cellCt = 1 : length([cellData.cellID])
            if cellData(cellCt).hasInfo==1
                cellData = getFlurInfo(cellData,videocell_flur1,halfCropSize,cellCt,1); 
                %well=cellData(cellCt).well;
                %imwrite(cellData(cellCt).flur1_img,[pathToDir,'ws/',expName,'/',well,'/',int2str(cellCt),'_flur1.tif'],'tiff','Compression','none');
                %IsegMask=cellData(cellCt).flur1_mask;
                %boundary=bwperim(IsegMask,8);
                %imwrite(boundary,[pathToDir,'ws/',expName,'/',well,'/',int2str(cellCt),'_flur1Bnd.tif'],'tiff','Compression','none');
            end    
        end
        disp('flur1 channel data loaded, processed and stored');
        clear videocell_flur1; % to release occupied RAM as the stored variable is not needed further
    end
    
    if startimg_flur2>0, [videocell_flur2,imgNames] = imgfolder2videocell(dirstring, startimg_flur2, cyclesize, numimgs); end;
    if startimg_flur2>0 % pSMAC
        for cellCt = 1 : length([cellData.cellID])
            if cellData(cellCt).hasInfo==1
                cellData = getFlurInfo(cellData,videocell_flur2,halfCropSize,cellCt,2,1);
                % the 6th input argument is 0 if there is no limit on the number of fragments/components considered (put to 0 only if there are many instances of fragmented pSMAC).
                
                %well=cellData(cellCt).well;
                %imwrite(cellData(cellCt).flur2_img,[pathToDir,'ws/',expName,'/',well,'/',int2str(cellCt),'_flur2.tif'],'tiff','Compression','none');
                %IsegMask=cellData(cellCt).flur2_mask;
                %boundary=bwperim(IsegMask,8);
                %imwrite(boundary,[pathToDir,'ws/',expName,'/',well,'/',int2str(cellCt),'_flur2Bnd.tif'],'tiff','Compression','none');
            end    
        end
        disp('flur2 channel data loaded, processed and stored');
        clear videocell_flur2; % to release occupied RAM as the stored variable is not needed further
    end
    
    if startimg_flur3>0, [videocell_flur3,imgNames] = imgfolder2videocell(dirstring, startimg_flur3, cyclesize, numimgs); end;
    if startimg_flur3>0 % constim
        for cellCt = 1 : length([cellData.cellID])
            if cellData(cellCt).hasInfo==1
                cellData = getFlurInfo(cellData,videocell_flur3,halfCropSize,cellCt,3);
                %well=cellData(cellCt).well;
                %imwrite(cellData(cellCt).flur3_img,[pathToDir,'ws/',expName,'/',well,'/',int2str(cellCt),'_flur3.tif'],'tiff','Compression','none');
                %IsegMask=cellData(cellCt).flur3_mask;
                %boundary=bwperim(IsegMask,8);
                %imwrite(boundary,[pathToDir,'ws/',expName,'/',well,'/',int2str(cellCt),'_flur3Bnd.tif'],'tiff','Compression','none');
            end    
        end
        disp('flur3 channel data loaded, processed and stored');
        clear videocell_flur3; % to release occupied RAM as the stored variable is not needed further
    end
    
    if startimg_flur4>0, [videocell_flur4,imgNames] = imgfolder2videocell(dirstring, startimg_flur4, cyclesize, numimgs); end;
    if startimg_flur4>0 % reporter
        for cellCt = 1 : length([cellData.cellID])
            if cellData(cellCt).hasInfo==1
                cellData = getFlurInfo(cellData,videocell_flur4,halfCropSize,cellCt,4);
                %well=cellData(cellCt).well;
                %imwrite(cellData(cellCt).flur4_img,[pathToDir,'ws/',expName,'/',well,'/',int2str(cellCt),'_flur4.tif'],'tiff','Compression','none');
                %IsegMask=cellData(cellCt).flur4_mask;
                %boundary=bwperim(IsegMask,8);
                %imwrite(boundary,[pathToDir,'ws/',expName,'/',well,'/',int2str(cellCt),'_flur4Bnd.tif'],'tiff','Compression','none');
            end
            if mod(cellCt,100)==0
                %fprintf('flur4 channel %d th cell analyzed\n',cellCt);
            end    
        end
        disp('flur4 channel data loaded, processed and stored');
        clear videocell_flur4; % to release occupied RAM as the stored variable is not needed further
    end
    display('All fluorescence channels processed');
    
    % cSMAC based synapse symmetry score
    if startimg_flur1>0 && startimg_flur2>0
        for cellCt= 1 : length([cellData.cellID])
            if cellData(cellCt).hasInfo==1
                cellData = calcSynSymmetry(cellData, cellCt);
            end
        end
    end
    
    % PKCtheta enrichment on co-stim (for recruitment of CD80)
    if startimg_flur3>0 && startimg_flur4>0
        for cellCt= 1 : length([cellData.cellID])
            if cellData(cellCt).hasInfo==1
                cellData = reporterEnrichment(cellData,cellCt,3); % enrichment on segmented costim
            end
        end
    end
    % reporter not included before permeablizatn
    % convert to um scale from pixel units
    cellData=convertUnits_afterPerm(cellData,numUmPerPix_convert);
    
    % save data into separate .mat files that pertain to each unique well in the dataset.
    saveIndWellData(cellData, pathToDir, expName);
    
    % remove the mask/image related fields from the main structure
    %delFields={'cellMask','dilCellMask','bgMask','flur1_img','flur1_mask','flur2_img','flur2_mask','flur3_img','flur3_mask','flur4_img','flur4_mask'};
    delFields={'cellMask','dilCellMask','bgMask','flur3_img','flur3_mask','flur4_img','flur4_mask'}; % no flur1 annd flur2
    cellData=rmfield(cellData,delFields);
    
    % function fieldnames(S) returns a cell array of strings that tell the field names of the structure S.
    % To save specific fields (a and c in example) of a structure (S in example): save newstruct.mat -struct S a c
            
    % save matlab .mat file again (overwrites the previous .mat file written before)
    %timeSoFar = toc;
    resultsFile = [pathToDir,'ws/', expName,'_results.mat'];
    save(resultsFile,'cellData'); 
    %save(resultsFile,'cellData', -v7.3); 
    % v7.3 allows more than 2GB to be stored in mat file on 64bit computers
    % version 7.3 uses HDF5 format which apparently creates larger files despite compression for cells and structures.
    disp(['Analysis finished. Results saved as: ', resultsFile]);
    
    reportFile=[pathToDir,'ws/', expName,'_report.mat'];
    report=create96wellReport_afterPerm(cellData);
    save(reportFile,'report');
    disp(['Report created and saved as: ', reportFile]);
    
    toc % should be reporting the total time for analysis
end
