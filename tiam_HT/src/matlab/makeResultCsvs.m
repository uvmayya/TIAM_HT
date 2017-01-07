
function makeResultCsvs(datacell,resultDataType,video,irmOnly,params,arrestCoefThresh)

% this function makes csv files containing the results of a tcmat analysis

% input: datacell, the standard datacell containing analysis information
% input: resultDataType, =0 for per cell track, =1 for per frame, =2 for both
% input: video, a java video object containing things like channel order, and analysis name
% input: params, a vector of algorithm parameters



% if irmOnly is given and ==1, only keep the cell-tracks in data with enough irm attachment
if nargin>3
	if irmOnly==1
		datacell = keepIrmOnOnly(datacell);
		datacell = get_speed_new(datacell);
		datacell = get_correctedConfinementIndex(datacell);
		datacell = get_arrestCoefficient(datacell, arrestCoefThresh, 10);
		fprintf('Only attached cell tracks ("irm on") are kept.\n')
	end
end


if resultDataType == 0 || resultDataType == 2

	% results per cell track
		% each row a cell track, each column a feature
		% features
			% mean speed (over all frames), step 1 and step 4
			% normalized displacement
			% displacement
			% mean irm (over "on frames", of those on over 5% of the length, else 0)
			% mean fluorescent value (for each fluor channel)
			% arrest coefficient
			% [abs(turnAngle)] ?? (vivek didn't ask for?)
			% confinement index

	perCtMat = [];
	for i = 1:length(datacell)
		perCtMat(i,1) = i; % cell track index
		perCtMat(i,2) = datacell{i}(1,8); % cell-type (0 for neither)
		perCtMat(i,3) = mean(datacell{i}(:,9)); % step 1 speed
		perCtMat(i,4) = mean(datacell{i}(:,10)); % step 4 speed
		perCtMat(i,5) = mean(datacell{i}(:,11)); % step 8 speed
		perCtMat(i,6) = mean(datacell{i}(:,12)); % full path speed / normalized displacement
		perCtMat(i,7) = mean(datacell{i}(:,13)); % displacement
		if length(find(datacell{i}(:,5)))/size(datacell{i},1) > 0.1 % if irm on >10% of track
			perCtMat(i,8) = mean(datacell{i}(find(datacell{i}(:,5)),5)); % irm on area
		else
			perCtMat(i,8) = 0;
		end
		perCtMat(i,9) = mean(datacell{i}(:,6)); % fluor 1 value
		perCtMat(i,10) = mean(datacell{i}(:,7)); % fluor 2 value
		perCtMat(i,11) =  datacell{i}(1,14); % arrest coefficient
		perCtMat(i,12) = mean(abs(datacell{i}(:,15))); % abs(turn angle)
		perCtMat(i,13) = mean(datacell{i}(:,15)); % non-abs turn angle (is this vectorial turn angle??)
		perCtMat(i,14) = datacell{i}(1,16); % confinement index
		perCtMat(i,15) = mean(datacell{i}(:,19)); % 17 is eccentricity, 18 is circularity, 19 is aspect ratio as a polarity measure is reported
	end

	% to save csvs
	nameLength = 14; % length of this function name "makeResultCsvs"
	pathToFn = mfilename('fullpath');
	pathToDir = pathToFn(1:end-nameLength);

	% ensure that csv files are not overwritten
	csvdirString = [pathToDir, '../../csv/'];
	initSaveString = [char(video.name),'_perCellTrack'];
	saveString = [initSaveString,'.csv'];
	for j=2:50
		alreadyInDir = isFileInDir(csvdirString,saveString);
		if alreadyInDir==0, break; end
		saveString = [initSaveString,num2str(j),'.csv'];
	end

	% save file
	csvwrite([csvdirString,saveString],perCtMat);

	% add params to end of file
	f = fopen([csvdirString,saveString], 'at');
	fprintf(f,'Algorithm parameters: image scale: %f, edge value: %f, radius min: %f, radius max: %f, gradient thresh: %f, search radius: %f, min cell separation: %f, dark image: %f', params);
	fclose(f);

	% display output to user
	toprint = ['Saved csv: ',saveString,'\n'];
	fprintf(toprint);
end


if resultDataType == 1 || resultDataType == 2
	
	% results per frame
		% each row a video frame, each column a feature
		% features
			% mean speed (over cell tracks at given frame), step 1 and step 4
			% mean irm (for those "on" at given frame)
			% [abs(turnAngle)] ?? (vivek didn't ask for?)


	perFrMat = [];
	perframe = {};
	for i = 1:length(datacell)
		for f = 1:size(datacell{i},1)
			frame = datacell{i}(1,1)+f-1;
			if size(perframe,1) < frame
				perframe(frame,1:5) = {[],[],[],[],[]};     %%%%% for each attribute to grab, must supply an empty array here.
			end	

			perframe{frame,1}(end+1) = datacell{i}(f,9);  % step 1 speed
			perframe{frame,2}(end+1) = datacell{i}(f,10); % step 4 speed
			perframe{frame,3}(end+1) = datacell{i}(f,11); % step 8 speed
			perframe{frame,4}(end+1) = datacell{i}(f,5); % irm area
			perframe{frame,5}(end+1) = datacell{i}(f,19); % 17 is eccentricity, 18 is circularity, 19 is aspect ratio as a polarity measure is reported

		end
	end
	% average values in perframe cell and put into perFrMat
	for f = 1:size(perframe,1)
		perFrMat(f,2) = mean(perframe{f,1}); % step 1 speed
		perFrMat(f,3) = mean(perframe{f,2}); % step 4 speed
		perFrMat(f,4) = mean(perframe{f,3}); % step 8 speed
		if (length(find(perframe{f,4}))/length(perframe{f,4})) > 0.1 % if irm on >10% of track
			perFrMat(f,5) = mean(perframe{f,4}(find(perframe{f,4}))); % irm on area
		else
			perFrMat(f,5) = 0;
		end
		perFrMat(f,5) = mean(perframe{f,5}); % polarity
	end
	perFrMat(:,1) = 1:size(perframe,1);


	% % to save csvs
	% nameLength = 14; % length of this function name "makeResultCsvs"
	% pathToFn = mfilename('fullpath');
	% pathToDir = pathToFn(1:end-nameLength);

	% csvdir = dir([pathToDir, '../../csv/']);
	% % check if savestring = [name,'_result_perCellTrack.csv'] exists in this dir
	% 	% if so, change savestring to [name,'_result_perCellTrack_2.csv']
	% 		% check if that exists too
	% 		% keep increasing until it works

	% to save csvs
	nameLength = 14; % length of this function name "makeResultCsvs"
	pathToFn = mfilename('fullpath');
	pathToDir = pathToFn(1:end-nameLength);

	% ensure that csv files are not overwritten
	csvdirString = [pathToDir, '../../csv/'];
	initSaveString = [char(video.name),'_perFrame'];
	saveString = [initSaveString,'.csv'];
	for j=2:50
		alreadyInDir = isFileInDir(csvdirString,saveString);
		if alreadyInDir==0, break; end
		saveString = [initSaveString,num2str(j),'.csv'];
	end

	% save file
	csvwrite([csvdirString,saveString],perFrMat);
	
	% add params to end of file
	f = fopen([csvdirString,saveString], 'at');
	fprintf(f,'Algorithm parameters: image scale: %f, edge value: %f, radius min: %f, radius max: %f, gradient thresh: %f, search radius: %f, min cell separation: %f, dark image: %f', params);
	fclose(f);

	% display output to user
	toprint = ['Saved csv: ',saveString,'\n'];
	fprintf(toprint);

end



% if two fluor channels, save a csv for each showing the positions of all cells

	% not sure exactly the best way to do this to get any sort of good visualization yet




