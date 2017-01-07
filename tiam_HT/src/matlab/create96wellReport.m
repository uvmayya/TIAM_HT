function report=create96wellReport(cellData)
% takes cellData that doesn't have masks and images

wellList={cellData.well};
uniqWells=unique(wellList); % a row cell-array of strings

report=struct([]); % empty structure initialization
%report=cell(length(uniqWells),length(fieldnames(cellData))+4);
for i=1:length(uniqWells)
    cellDataPerWell=cellData(strcmp(wellList,uniqWells{i})); % extracts all fields that belong to the relevant cell
    report(i).well=uniqWells{i};
    report(i).nDetect=length([cellDataPerWell.cellID]);
    report(i).nCells=nnz([cellDataPerWell.hasInfo]);
    report(i).polarity=mean([cellDataPerWell.polarity]);
    report(i).n_cSMACs=nnz([cellDataPerWell.flur1_hasInfo]);
    report(i).cSMACint=mean([cellDataPerWell.flur1_int]);
    report(i).cSMACarea=mean([cellDataPerWell.flur1_area]);
    report(i).n_pSMACs=nnz([cellDataPerWell.flur2_hasInfo]);
    report(i).pSMACint=mean([cellDataPerWell.flur2_int]);
    report(i).pSMACarea=mean([cellDataPerWell.flur2_area]);
    report(i).n_pSMACring=nnz([cellDataPerWell.flur2_broken]==0);
    report(i).n_pSMACbroken=nnz([cellDataPerWell.flur2_broken]==1);
    report(i).n_pSMACnoRing=nnz([cellDataPerWell.flur2_broken]==2);
    report(i).synSymmetry=mean([cellDataPerWell.synSymmetry]);
    report(i).costimInt=mean([cellDataPerWell.flur3_int]);
    report(i).costimArea=mean([cellDataPerWell.flur3_area]);
    report(i).reporterInt=mean([cellDataPerWell.flur4_int]);
    report(i).reporterArea=mean([cellDataPerWell.flur4_area]);
    report(i).reporterEnrichment=mean([cellDataPerWell.reporterEnrichment]);
end    
    
end