function getParamsFromGUI()

% the following is matlab code that makes java objects / calls java methods (including the tcmat gui).

% basic process:
% 0.) asks user which frame number to use (out of possible frames). loads that single frame.
% 1.) allows user to resize image (in case of varying cell sizes).
% 2.) allows user to adjust image brightness (in case of dark images).
% 3.) allows user to adjust the amount of edge edges extracted (ie adjust the canny filter)
% 4.) allows user to adjust accumulation array (a product of the hough transform)
% 5.) show detects overlayed on initial image
%		allows user to adjust size of blobs in search



% construct TcMatGui (and video objects
% ----------------------------------------
nameLength = 27; % length of: src/matlab/getParamsFromGUI
pathToFn = mfilename('fullpath');
pathToDir = pathToFn(1:end-nameLength);
tcmat = TcMatGui(pathToDir);
video = tcmat.getVideo();


% the following the main loop that the program follows
% ----------------------------------------------------
newloop = 0;
while newloop==0

	% get information about video
	% ---------------------------
	tcmat.showMessage('The GUI works only with 512-by-512 pixel image series.');
    dirString = char(video.getDir());
	imgFiles = dir(dirString);
	numChannels = video.getNumChannels();
	numFrames = (size(imgFiles,1)-2)/numChannels;

       
	% get user response about detection parameter tuning process
	% ----------------------------------------------------------
	doDetectionParameterTuning = tcmat.showConfirmMessage('Would you like to tune detection parameters for this video? If not, default parameters will be chosen.');

	if doDetectionParameterTuning == 0
		% choose frame number on which to tune
		% ------------------------------------
		whichFrame = tcmat.askWhichFrameForTuner(numFrames);

		% load image and display on tcmat
		% -------------------------------
		% the following returns the whichFrame_th DIC image (and handles the . and .. files)
		videoimg = imread([dirString, '/', imgFiles(((whichFrame-1)*numChannels)+2+video.getDicChannel()).name]);

		% we store the initial image before any changes (this is displayed at the end)
		initimg = videoimg;

		% convert to java Image and display on tcmat
		javaimg = im2java(videoimg);
		tcmat.showImage(javaimg);

		% if videoimg three-dimensional (has color), make grayscale
		% ---------------------------------------------------------
		if length(size(videoimg)) == 3
			videoimg = rgb2gray(videoimg);
		end

		% adjust image size
		% -----------------
		nextloop = 0;
		resize = 1;
		resize_range = [0.7, 1.9];
		while(nextloop == 0)
			javaimg = im2java(imresize(videoimg, resize));
			whichOpt = tcmat.getUserResponse('Make image bigger.', 'Make image smaller.', 'Choose current image size.', 'Resize the image so that cells are about the size as those in the sample image.<br> Sample image is in page 6 of the user-guide.<br>Scaling ensures that default radius range used for CHT works well.', javaimg);

			if whichOpt == 3
				nextloop = 1;
			elseif whichOpt == 1
				if resize <= resize_range(2)-0.1;
					resize = resize + 0.1;
				else
					tcmat.showMessage('Cannot resize any larger! Either make image smaller or accept current size.');
				end
			elseif whichOpt == 2
				if resize >= resize_range(1)+0.1;
					resize = resize - 0.1;
				else
					tcmat.showMessage('Cannot resize any smaller! Either make image larger or accept current size.');
				end
			else
				tcmat.showMessage('You have to choose to make image bigger, smaller, or accept its current size!');
			end
		end
		videoimg = imresize(videoimg, resize);


		% adjust image darkness
		% ---------------------

		nextloop = 0;
		isdark = 0;
		test = videoimg;
		while(nextloop == 0)
			javaimg = im2java(test); 
			whichOpt = tcmat.getUserResponse('Make image lighter.', 'Revert to original image.', 'Choose current image.', 'Is the image too dark? Look at sample image for reference.<br>Sample image is in page 6 of the user-guide.<br>Dark image undermines edge detection.', javaimg);
			if whichOpt == 3
				nextloop = 1;
			elseif whichOpt == 1
				load histobob_mid
				% test = histeq(test, histobob_mid);
				test = imadjust(histeq(test, histobob_mid), [0.1, 0.5], []);
				isdark = 1;
				tcmat.showMessage('Note: the image will be made lighter. If it looks washed out, that is often ok for decent detection.');
			elseif whichOpt == 2
				test = videoimg;
				isdark = 0;
			else
				tcmat.showMessage('You have to choose to make image lighter or accept its original darkness!');
			end
		end
		videoimg = test;


		% adjust edge value
		% -----------------

		nextloop = 0;
		edgevalue = 0.2;
		edgevalue_range = [0.05, 0.5];
		while(nextloop == 0)

			% compute edge image
			canny = edge(videoimg, 'canny', edgevalue);
			logfilt = edge(videoimg, 'log', 0.001);
			for i = 1 : size(logfilt, 1)
				for l = 1 : size(logfilt, 2)
					if logfilt(i, l) == 1
						canny(i, l) = 1;
					end
				end
			end
			test = im2uint8(canny);

			% make test2 to overlay on white background
			test2 = test;
			test2(:) = 1;
			avepixel = 65 / 255; 
			test2 = imoverlay(test2, canny, [avepixel, avepixel, avepixel]);  % canned function
			test2 = rgb2gray(test2);
			test2 = im2uint8(test2);
			javaimg1 = im2java(test2);

			whichOpt = tcmat.getUserResponse('Increase edge density.', 'Decrease edge density.', 'Choose current edge density.', 'Sensitivity threshold for edge detection is chosen here.<br>Increase the edge density until the edges of each cell can be clearly seen.<br>Noisy edges within and around cells is ok.', javaimg1);
			if whichOpt == 3
				nextloop = 1;
			elseif whichOpt == 2
				if edgevalue <= edgevalue_range(2)-0.05;
					edgevalue = edgevalue + 0.05;
				else
					tcmat.showMessage('Cannot decrease edge more! Either increase edge density or accept current edge density.');
				end
			elseif whichOpt == 1
				if edgevalue >= edgevalue_range(1)+0.05;
					edgevalue = edgevalue - 0.05;
				else
					tcmat.showMessage('Cannot increase edge more! Either decrease edge density or accept current edge density.');
				end
			else
				disp('You have to either increase the edge density, decrease the edge density, or keep the current density.');
			end
		end



		% ---------------------------------------------------------
		% note: test is now the main image that we are working with
		% ---------------------------------------------------------
		% videoimg is the initial (resized) image that we show final results on top of


		% adjust accum array / radius range
		% ---------------------------------

		nextloop = 0;
		radrange = [5,15];
		radrange_range = [2,12];  % this is range for lowerbound of radrange
		chtparam1 = 5; chtparam2 = 15; % these are default values---chosen actually in next section.
		while(nextloop == 0)

			% show accum image

			[accum, circen, cirrad] = CircularHough_Grd(test, radrange, chtparam1, chtparam2);  % canned function
			javaimg = im2java(uint8(accum));

			%tcmat.showImage(javaimg);
			% userinput = input('Type m for larger blobs, l for smaller blobs, y to accept current value.\n', 's');

			whichOpt = tcmat.getUserResponse('Increase hough accum array blob size.', 'Decrease hough accum array blob size.', 'Choose current hough accum array blob size.', 'Radius range for hough accum is fine tuned here.<br>Try to have roughly one blob per cell.', javaimg);

			if whichOpt == 3
				nextloop = 1;
			elseif whichOpt == 1
				if radrange(1) <= radrange_range(2)-1;
					radrange(1) = radrange(1) + 1;
					radrange(2) = radrange(2) + 1;
				else
					tcmat.showMessage('Cannot make blobs bigger! Either decrease blob size or accept the current value.');
				end
			elseif whichOpt == 2
				if radrange(1) >= radrange_range(1)+1;
					radrange(1) = radrange(1) - 1;
					radrange(2) = radrange(2) - 1;
				else
					tcmat.showMessage('Cannot make blobs smaller! Either decrease blob size or accept the current value.');
				end
			else
				tcmat.showMessage('You have to either increase blob size, decrease blob size, or accept the current blob size.');
			end
		end


		% adjust search radius
		% --------------------

		nextloop = 0;
		searchrad = 15;
		searchrad_range = [5,20]; % appears like above 19 there is an error message due to line 488 is CircularHough_Grd function.
		gradthresh = 10; % default gradient thresh value
		min_cell_sep = 6; % default minimum cell separation
		while(nextloop == 0)

			% detect cells
			[accum, circen, cirrad] = CircularHough_Grd(test, radrange, gradthresh, searchrad);  % canned function

			% Remove duplicate/overlapping/too-close centers
			circen = sortrows(circen);
			circlesToKeep = [1];
			for i = 2 : size(circen, 1)
				toadd = 1;
				for k = 1 : i-1	
					if (norm(circen(i,:) - circen(k,:)) < min_cell_sep)
						toadd = 0;
					end
				end
				if toadd == 1
					circlesToKeep = [circlesToKeep; i];
				end
			end
			circen = circen(circlesToKeep, :);	
			centers = circen;

			% remove bad centers via blobcheck (cross reference)
			se90 = strel('line', 6, 90);
			se0 = strel('line', 6, 0);
			diam = strel('diamond', 9);
			disk = strel('diamond', 3);
			% take canny image and dilate, fill, erode, and dilate
			dil = imdilate(canny, [se90, se0]);
			fill = imfill(dil, 'holes');
			rawimg = im2uint8(fill);
			for b = 1 : 1
				rawimg = imerode(rawimg, diam);
				rawimg = imdilate(rawimg, disk);
			end
			% Remove centers over black space
			tokeep = [];
			for i = 1 : size(centers, 1)
				xpos = floor(centers(i, 1));
				ypos = floor(centers(i, 2));
				center = rawimg(ypos, xpos);
				up = rawimg(ypos+1, xpos);
				down = rawimg(ypos-1, xpos);
				left = rawimg(ypos, xpos-1); % corrected from rawimg(ypos-1,xpos) as Willie had it
				right = rawimg(ypos, xpos+1);
				centerColor = (center/5) + (up/5) + (down/5) + (left/5) + (right/5);
				if (centerColor == 255) % Willie had used >153 based on his inspection
					tokeep = [tokeep; i];
				end
			end
			centers = centers(tokeep, :);

			% resize x and y positions of centers based on initial resize
			centers(:,1) = centers(:,1)/resize;
			centers(:,2) = centers(:,2)/resize;

			% make mask and overlay detected points
			mask = makeCentersMask(initimg,centers);
			javaimg = im2java(imoverlay(initimg, mask', [1,0,0]));

			whichOpt = tcmat.getUserResponse('Increase search radius (look for larger hough peaks).', 'Decrease search radius (look for smaller hough peaks).', 'Choose current search radius value.', 'Hough accum array maxima are shown in red to represent cell centroids.<br>Use the search radius that visually gives a good detection result for most cells.', javaimg);

			if whichOpt == 3
				nextloop = 1;
			elseif whichOpt == 1
				if searchrad <= searchrad_range(2)-1;
					searchrad = searchrad + 1;
				else
					tcmat.showMessage('Cannot search for bigger blob peaks. Either search for smaller blob peaks or accept current search radius value.');
				end
			elseif whichOpt == 2
				if searchrad >= searchrad_range(1)+1;
					searchrad = searchrad - 1;
				else
					tcmat.showMessage('Cannot search for bigger blob peaks. Either search for smaller blob peaks or accept current search radius value.');
				end
			else
				tcmat.showMessage('You have to either search for bigger blob peaks, smaller blob peaks, or accept the current search radius value.');
			end
        end

        tcmat.showMessage('gradientThresh of 10 and minCellSeparation of 6 work well');
        
		% make params vector
		% ------------------
		params = [resize, edgevalue, radrange(1), radrange(2), gradthresh, searchrad, min_cell_sep, isdark];
		%disp('Detection params:');
        %fprintf('Detection params for %s: \n imageScale %.1f \n egdeValue %.2f \n radiusMin %d \n radiusMax %d \n gradientThresh %d \n searchRadius %d \n minCellSeparation %d \n isDark %d \n', char(video.getName()), resize, edgevalue, radrange(1), radrange(2), gradthresh, searchrad, min_cell_sep, isdark);
		%disp(params);

	else

		% set default parameters
		% ----------------------
		resize = 0.7; edgevalue = 0.1; radrange(1) = 4; radrange(2) = 16; gradthresh = 10; searchrad = 16; min_cell_sep = 6; isdark = 0;
		params = [resize, edgevalue, radrange(1), radrange(2), gradthresh, searchrad, min_cell_sep, isdark];
		%disp('Detection params:');
		%fprintf('Detection params %s: \n imageScale %.1f \n egdeValue %.2f \n radiusMin %d \n radiusMax %d \n gradientThresh %d \n searchRadius %d \n minCellSeparation %d \n isDark %d \n', char(video.getName()), resize, edgevalue, radrange(1), radrange(2), gradthresh, searchrad, min_cell_sep, isdark);
        %disp(params);

	end

	% detection tuning finished. ask user to "ok" algorithm on entire video
	% ---------------------------------------------------------------------
	tcmat.showMessage('Press ok to run detection on all images.');


	% Run general algorithm on all frames in video
	% --------------------------------------------

	% reading images into videocell, videocell_irm, videocell_memory, and videocell_naive
	% -----------------------------------------------------------------------------------
	dirstring = dirString;
	cyclesize = numChannels;
	numimgs = numFrames;
	startimg_irm = video.getIrmChannel();
	startimg_memory = video.getFluorChannel1();
	startimg_naive = video.getFluorChannel2();
	startimg = video.getDicChannel();

	tcmat.displayAlgorithmMessage('Loading images...', 1);
	[videocell,imgNames] = imgfolder2videocell(dirstring, startimg, cyclesize, numimgs);
	%if startimg_irm>0, videocell_irm = imgfolder2videocell(dirstring, startimg_irm, cyclesize, numimgs); end;
	%if startimg_memory>0, videocell_memory = imgfolder2videocell(dirstring, startimg_memory, cyclesize, numimgs); end;
	%if startimg_naive>0, videocell_naive = imgfolder2videocell(dirstring, startimg_naive, cyclesize, numimgs); end;
	tcmat.displayAlgorithmMessage('All images from all channels loaded.', 0);

	% cell detection
	% --------------
	tcmat.displayAlgorithmMessage('...Starting cell detection.', 1);
	statscell = celldetect_new(videocell, params, tcmat);

    % result output
    %--------------
	resultsFile = [pathToDir,'ws/', char(video.getName()),'_params.mat'];
	save(resultsFile,'statscell','params');
    fprintf('Detection params for %s: \n imageScale %.1f \n egdeValue %.2f \n radiusMin %d \n radiusMax %d \n gradientThresh %d \n searchRadius %d \n minCellSeparation %d \n isDark %d \n', char(video.getName()), resize, edgevalue, radrange(1), radrange(2), gradthresh, searchrad, min_cell_sep, isdark);
    
    % whether to initiate another round of optimization?
	newloop = tcmat.repeatOrQuit();

	if newloop == 0
		tcmat.displayAlgorithmMessage('------------------------------------------------------------------------', 1);
		tcmat.makeVideo(pathToDir);
		video = tcmat.getVideo();
	end

end

