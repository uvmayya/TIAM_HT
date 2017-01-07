
function cellData = convertUnits(cellData,lengthConvert)

% this function converts the units of relevant fields 
% input: lengthConver, micrometers-per-pixel length factor
% keeping centroids in pixel units, only converting area to um2


for cellCt = 1:length([cellData.cellID])
    if cellData(cellCt).hasInfo
        cellData(cellCt).area = cellData(cellCt).area*lengthConvert*lengthConvert;
    end
    if cellData(cellCt).flur1_hasInfo
        cellData(cellCt).flur1_area = cellData(cellCt).flur1_area*lengthConvert*lengthConvert;
    end    
	if cellData(cellCt).flur2_hasInfo
        cellData(cellCt).flur2_area = cellData(cellCt).flur2_area*lengthConvert*lengthConvert;
    end    
    if cellData(cellCt).flur3_hasInfo
        cellData(cellCt).flur3_area = cellData(cellCt).flur3_area*lengthConvert*lengthConvert;
    end
    if cellData(cellCt).flur4_hasInfo
        cellData(cellCt).flur4_area = cellData(cellCt).flur4_area*lengthConvert*lengthConvert;
    end    
end
