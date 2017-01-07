function batchHTsubmit_example()

% set up batch jobs in this file (this calls tcmatBatchScript.m at the end)
addpath(genpath('C:/Users/mayyav01/Documents/MATLAB/tiam_forOperatta/src'));

% jobs is constructed and passed as a parameter to tcmatBatchScript.m
jobs = {};


% *************************************************
%                    Job Form
% *************************************************

expName = '052815_20xhighNA_trial'; % instructive name indicating the experiment and the analysis
dirString = 'C:/Users/vmayya/Documents/subprojects/operattaDataAnals/061815_initialProgSetUp/052815_highNA_decoded_subset/'; % relative or full path to the folder containing tiff series
maskImgPath = 'C:/Users/vmayya/Documents/subprojects/operattaDataAnals/061815_initialProgSetUp/maskImage.tif' ; % relative or full path with file name of the image to be used as mask; mask should be a binary image (0 and 255) with the same size as the images
numChannels = 3; % can handle upto 5;
numFields = 39; %163

% assign numbers (1-5) for each of the 5 possible channels indicating the order in which the channels appear. if channel does not exist, write 0 (there must be a non-zero for startimg_dic).
startimg_dic = 3;
startimg_flur1 = 1;
startimg_flur2 = 2;
startimg_flur3 = 0;
startimg_flur4 = 0;

% params for detection
imageScale = 1.4;
edgeValue = 0.1;
radiusMin = 5;
radiusMax = 15;
gradientThresh = 10;
searchRadius = 16;
minCellSeparation = 6;
darkImage = 0; % 0 or 1
detectParams = [imageScale, edgeValue, radiusMin, radiusMax, gradientThresh, searchRadius, minCellSeparation, darkImage];

% conversion and other specifications
numUmPerPix_convert = 6.45;
halfCropSize = 14; % for resting T cells imaged with 20x objective 12 pixels works out well; this is used for cropping cells for feature extractions

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
