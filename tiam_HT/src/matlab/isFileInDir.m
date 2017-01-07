
function answer = isFileInDir(dirString, fileName)

% this function returns 1 if fileName is in the dir specified by dirString and 0 otherwise


files = dir(dirString);
answer = 0;
for i = 3:size(files,1)
	if strcmp(files(i).name,fileName)
		answer = 1;
		break
	end
end