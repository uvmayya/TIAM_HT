
function statscell = celldetect_new(videocell, params, tcmat)

% this function performs detection of T cells 
% -------------------------------------------



% default params
% --------------

if nargin < 2
	params = [1.2, 0.1, 3, 13, 10, 16, 5];  % default params
	% params = [1, 0.2, 5, 15, 10, 15, 5];  % default params
end

% add param (pertaining to dark video) if it doesn't exist
% --------------------------------------------------------

if length(params < 8)
	params(8) = 0;
end


tic

% loop through all frames
% -----------------------

for frame = 1 : length(videocell)

	% detection
	% ---------

	centers = celldetect_cht_procedure(videocell{frame}, params(2), params(3), params(4), params(5), params(6), params(7), params(1), params(8));
	statscell{frame} = centers;

	% display progress on screen
	% --------------------------
	
	disp('celldetect complete for frame = ');
	disp(frame);

	% display on TC-MAT Gui
	algoString = ['Cell detection complete for frame ', int2str(frame)];
	if frame < length(videocell)
		tcmat.displayAlgorithmMessage(algoString, 0);
	else
		tcmat.displayAlgorithmMessage('Cell detection complete for all frames.', 0);
	end


	% draw image of detected cells on gui
	mask = makeCentersMask(videocell{frame}, centers);
	javaimg = im2java(imoverlay(videocell{frame}, mask', [1,0,0]));
	tcmat.showImage(javaimg);
	
end

toc