
function cellData = celldetect_batch(videocell, params, maskImage, imgName)

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
totCellCt=0;
cellData=struct([]); % initialize the cellData structure
for frame = 1 : length(videocell)

	% detection
	% ---------

	centers = celldetect_cht_procedure(videocell{frame}, params(2), params(3), params(4), params(5), params(6), params(7), params(1), params(8));
	%statscell{frame} = centers;
    
    % select cells if present within the mask area
    toKeep=[];
    for frCellCt = 1:size(centers,1)
        x_pixel=round(centers(frCellCt,1));
        y_pixel=round(centers(frCellCt,2));
        if maskImage(y_pixel,x_pixel)==255 %centroid present within the mask
            toKeep=[toKeep;frCellCt];
        %else display('there are rejected cells');
        end
    end
    centers=centers(toKeep,:); % selected centers returned
    
    % enter information into cellData
    for frCellCt = 1:size(centers,1)
        cellData(totCellCt+frCellCt).cellID = totCellCt+frCellCt; % gives cellID
        cellData(totCellCt+frCellCt).imgName = imgName{frame};
        [well,field]=getWellFieldInfo(imgName{frame});
        cellData(totCellCt+frCellCt).well=well;
        cellData(totCellCt+frCellCt).field=field;
        cellData(totCellCt+frCellCt).frame = frame;
        cellData(totCellCt+frCellCt).CHTcenterX = centers(frCellCt,1);
        cellData(totCellCt+frCellCt).CHTcenterY = centers(frCellCt,2);
    end    
    totCellCt=totCellCt+size(centers,1);
    %display(totCellCt);
        
	% display progress 	
	%disp('celldetect complete for frame = ');
	%disp(frame);
	algoString = ['Cell detection complete for frame ', int2str(frame)];
	if frame < length(videocell)
		disp(algoString)
	else
		disp('Cell detection complete for all frames.')
	end
	
end

toc