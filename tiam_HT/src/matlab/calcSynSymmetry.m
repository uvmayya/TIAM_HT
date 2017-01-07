function cellData = calcSynSymmetry(cellData, cellCt)

if cellData(cellCt).flur1_hasInfo && cellData(cellCt).flur2_hasInfo
    cSMACcentroid=cellData(cellCt).flur1_wtCentroid; % cSMAC centroid
    pSMACcentroid=cellData(cellCt).flur2_wtCentroid; % pSMAC centroid

    dist=pdist([cSMACcentroid;pSMACcentroid],'euclidean'); % distance between centroids

    area1=cellData(cellCt).area; % DIC outline area
    area2=nnz(bwconvhull(cellData(cellCt).flur2_mask)); % area of the convex hull of pSMAC
    area=mean([area1,area2]);
    effRad=realsqrt(area/pi); % effective radius

    cellData(cellCt).synSymmetry=dist/effRad;
end

end
