function cellData = reporterEnrichment(cellData,cellCt,whichFlurCh)
% it may be worth doing further segmentation of the picked channel to get
% only the highest intensity pixels

infoCond=0; % initialization
if whichFlurCh==1 && cellData(cellCt).flur1_hasInfo==1
    infoCond=1;
    IsegMask=cellData(cellCt).flur1_mask;
elseif whichFlurCh==2 && cellData(cellCt).flur2_hasInfo==1 
    infoCond=1;
    IsegMask=cellData(cellCt).flur2_mask;
elseif whichFlurCh==3 && cellData(cellCt).flur3_hasInfo==1 
    infoCond=1;
    IsegMask=cellData(cellCt).flur3_mask;    
else
    infoCond=0;
end    

if infoCond==1 && cellData(cellCt).flur4_hasInfo
    reporterFlur=cellData(cellCt).flur4_img;
    reporterSegMask=cellData(cellCt).flur4_mask;
    meanIntInside=mean(reporterFlur(IsegMask & reporterSegMask)); % AND operation
    meanIntOutside=mean(reporterFlur(~IsegMask & reporterSegMask));
    if isfinite(meanIntInside/meanIntOutside) % to deal with NaN values
        cellData(cellCt).reporterEnrichment=meanIntInside/meanIntOutside;
    else
        cellData(cellCt).reporterEnrichment=[];
    end
    
end

end