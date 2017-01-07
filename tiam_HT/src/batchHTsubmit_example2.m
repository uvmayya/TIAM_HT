function batchHTsubmit_detSegTrial()

% set up batch jobs in this file (this calls tcmatBatchScript.m at the end)
addpath(genpath('C:/Users/vmayya/Documents/MATLAB/tiam_HTtest/src'));

% jobs is constructed and passed as a parameter to tcmatBatchScript.m
jobs = {};


% *************************************************
%                    Job Form
% *************************************************

expName = 'detSegTrial'; % instructive name indicating the experiment and the analysis
dirString = 'C:/Users/vmayya/Documents/dataOx/synapseHT/040716_allWellSame/detectnSegmentatnTrial/'; % relative or full path to the folder containing tiff series
maskImgPath = 'C:/Users/vmayya/Documents/dataOx/synapseHT/040716_allWellSame/allWhiteMask.tif' ; % relative or full path with file name of the image to be used as mask; mask should be a binary image (0 and 255) with the same size as the images
numChannels = 5; % can handle upto 5;
numFields = 10; %163

% assign numbers (1-5) for each of the 5 possible channels indicating the order in which the channels appear. if channel does not exist, write 0 (there must be a non-zero for startimg_dic).
% maintain the convention in the channels (i.e. flur1 is always for cSMAC)
startimg_dic = 4;
startimg_flur1 = 2; % ucht1, cSMAC
startimg_flur2 = 5; % icam1, pSMAC
startimg_flur3 = 1; % costim
startimg_flur4 = 3; % reporter

% params for detection
imageScale = 1.4;
edgeValue = 0.05; % 0.15 
radiusMin = 7;
radiusMax = 20;
gradientThresh = 10;
searchRadius = 16;
minCellSeparation = 8;
darkImage = 0; % 0 or 1
detectParams = [imageScale, edgeValue, radiusMin, radiusMax, gradientThresh, searchRadius, minCellSeparation, darkImage];

% conversion and other specifications
numUmPerPix_convert = 0.325;
halfCropSize = 22; % for resting T cells imaged with 20x objective 12 pixels works out well; this is used for cropping cells for feature extractions

nextJob = {expName, dirString, maskImgPath, numChannels, numFields, startimg_dic, startimg_flur1, startimg_flur2, startimg_flur3, startimg_flur4, detectParams, numUmPerPix_convert, halfCropSize};
jobs{end+1} = nextJob; 

% *************************************************

%nextJob{1} = '052713_memBlock_2oCcl21';
%nextJob{2} = 'C:/Users/mayyav01/Documents/data/LSM510/052713_lfa1/anals/memBlock_2oCcl21/';
%include any other parameter that you want changed with the correct index
%nextJob{index}= changedValue;
%jobs{end+1} = nextJob;

%nextJob{1} = '052713_memIso_pt05oCcl21';
%nextJob{2} = 'C:/Users/mayyav01/Documents/data/LSM510/052713_lfa1/anals/memIso_pt05oCcl21/';
%include any other parameter that you want changed with the correct index
%nextJob{index}= changedValue;
%jobs{end+1} = nextJob;

%include as many jobs as needed

% call tcmatBatchScript.m
tiamHTbatchScript(jobs);
