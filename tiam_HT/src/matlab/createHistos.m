function histograms=createHistos(cellData,maxBins)
% create histograms of certain fields in cellData with a max of nBins

histograms=struct; % 1-by-1 scalar structure

histograms.cSMACint=calcHisto([cellData.flur1_int],maxBins);
histograms.cSMACarea=calcHisto([cellData.flur1_area],maxBins);
histograms.pSMACint=calcHisto([cellData.flur2_int],maxBins);
histograms.pSMACarea=calcHisto([cellData.flur2_area],maxBins);
histograms.reporterInt=calcHisto([cellData.flur4_int],maxBins);

histograms.synSymmetry=calcHisto([cellData.synSymmetry],maxBins);
histograms.reporterEnrichment=calcHisto([cellData.reporterEnrichment],maxBins);

end

function histogram=calcHisto(prop,maxBins)
% returns the histogram as two x and y vectors of any property prop input as an array
uniProp = sort(unique(prop)); % a vector output
if length(uniProp)<maxBins
    [histY,valX] = hist(prop,uniProp); % though uniProp is a vector, it works as per the 'xvalues' options in the hist function
    % using a vector input for second parameter allows uneven binning 
else
    [histY,valX] = hist(prop,maxBins); % row vector outputs for both lehisto and pixval
end

histY=histY'; valX=valX'; % convert to column vectors
histogram=cat(2,valX,histY);

end