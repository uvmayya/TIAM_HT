
function newDatacell = keepIrmOnOnly(datacell)


% this function returns a newDatacell that only keeps the entries in an input datacell with enough "irm on".

newDatacell = {};
for i = 1:length(datacell)
    mat = datacell{i};
    minOn = min(find(mat(:,5)));
    maxOn = max(find(mat(:,5)));
    newMat = mat(minOn:maxOn,:);
    if size(newMat,1)>10 || size(newMat,1)>=(size(mat,1)/2) % if there are "enough" irmOn entries
        newMat(:,1) = mat(1,1) + minOn - 1;
        newMat(:,2) = newMat(1,1) + size(newMat,1) - 1;
        newDatacell{end+1} = newMat;
    end
end
