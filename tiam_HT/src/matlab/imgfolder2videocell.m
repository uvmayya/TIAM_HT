function [videocell,imgName] = imgfolder2videocell(dirstring, startimg, cyclesize, numimgs)

% load folder info into struct array
%imgfiles = dir(dirstring); before
imgfiles = dir([dirstring,'/','*.tif']); %imgfiles is a n-by-1 structure with 5 fields (name, date, bytes, isdir, datenum), where n is the number of entries in the folder. 
% it looks like the default order in the output struct of 'dir' is based on alphabetical sorting of file names,
% this ultimately makes the sorting before reading files unnecessary. 

% convert to cell, sort by name, then convert back to struct array (to ensure correct order)
% ------------------------------------------------------------------------------------------

%% convert into cell
%fields = fieldnames(imgfiles);
%imgcell = struct2cell(imgfiles); % this gives 5-by-n cell array, where n is the number of entries in the folder
%sz = size(imgcell); %returns (5,n)

%% sort rows in cell form
%%imgcell = reshape(imgcell, sz(1), []); % with sz(1), [] is the arguments, the reshape function returns the cell array in the same form, hence no need for this operation. 
%imgcell = imgcell'; % to enable sorting by rows (i.e. have file names in the first column)
%imgcell = sortrows(imgcell, 1); % sort alphabetically based on the first column, which stores the names of files

%% convert back into original structure array
%%imgcell = reshape(imgcell', sz); %reshape wasn't found to be required.
%imgsorted = cell2struct(imgcell', fields, 1);%convert back to struct array with the same fields, dim 1 makes sure that the fields are applied to the rows


%%for id = 1:length(imgsorted)
    %fprintf('%d\n',id)
    %disp(imgsorted(id))
%%end


% make imgs into videocell
% ------------------------

if nargin < 2
	startimg = 1;				% default startimg
end

if nargin < 3
	cyclesize = 1;				% default cyclesize
end

if nargin < 4
	endimg = size(imgfiles,1);	% default endimg
end

if nargin >= 4
	%endimg = (numimgs*cyclesize)+2; %+2 takes care of . and .. entries in the folder list
    endimg = (numimgs*cyclesize); % since only *.tif are in the imgfiles list, I don't need to add +2 to take care of . and ..
end


%startimg = startimg + 2; % to handle . & .. in folder
% since only *.tif are in the imgfiles list, I don't need to add +2 to take care of . and ..

% load each image
videocell = {}; % willie's initiation
imgName = {};
for k = startimg : cyclesize : endimg
    videocell{end+1} = imread([dirstring, '/', imgfiles(k).name]);%directly using the original output which is sorted in alphabetical order of filenames by 'dir'.
	%videocell{end+1} = imread([dirstring, '/', imgfiles(k).name]); % in spite of doing separate sorting, Willie was still using the original list from the output of 'dir' at the beginning of the code in the function. 
    %videocell{end+1} = imread([dirstring, '/', imgsorted(k).name]); %if sorting in the code is needed.
    imgName{end+1} = imgfiles(k).name;
end
