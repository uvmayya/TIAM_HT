
function datacell = get_celltype(datacell)

% note that "memory" refers to fluor channel 1 and "naive" refers to fluor channel 2


% create avememory and avenaive vectors
avememory = [];
avenaive = [];
for cp = 1:length(datacell)
	avememory = [avememory, mean(datacell{cp}(:, 6))];
	avenaive = [avenaive, mean(datacell{cp}(:, 7))];
end

% normalize / regularize(?)
avememory = avememory - min(avememory);
avenaive = avenaive - min(avenaive);
if avememory ~= 0
	avememory = avememory./max(avememory);
end
if avenaive ~= 0 
	avenaive = avenaive./max(avenaive);	
end

% make cell type decision
for cp = 1 : length(datacell)
	if avememory(cp) > avenaive(cp)- 0.07 %%%%%
		datacell{cp}(:,8) = 1;
	else
		datacell{cp}(:,8) = 2;
	end
end

% display counts for memory cells and naive cells
memorycount = 0;
naivecount = 0;
for cp = 1 : length(datacell)
	if datacell{cp}(1,8) == 1
		memorycount = memorycount + 1;
	else
		naivecount = naivecount + 1;
	end
end
fprintf('Number of extracted cell-tracks in first fluor-channel: %d.\n', memorycount);
fprintf('Number of extracted cell-tracks in second fluor-channel: %d.\n', naivecount);