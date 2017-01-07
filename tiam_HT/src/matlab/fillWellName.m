function cellData=fillWellName(cellData)
% is use only if imgName is present but the well name is not present in the cellData structure. 

for cellCt=1:length([cellData.cellID])
    [well,field]=getWellFieldInfo(cellData(cellCt).imgName);
    cellData(cellCt).well=well;
end