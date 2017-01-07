
function getParamsFromGUImain()

% this function calls the GUI for optimizing the detection parameters on 512-by-512 image series

% add java and matlab paths
nameLength = 20; % length of this function name
pathToFn = mfilename('fullpath');
pathToDir = pathToFn(1:end-nameLength);
javaaddpath([pathToDir,'java']);
addpath(genpath([pathToDir,'matlab']));

% carry out algorithm to analyze video
getParamsFromGUI()


