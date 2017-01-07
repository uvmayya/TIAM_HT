function wellFileCount=getFilesPerWell(imgFolder)
% counts the number of files that are associated with a well based on the file name
% example file name: E - 2(fld 2 wv Blue - FITC).tif

imgFiles = dir(imgFolder); %imgfiles is a n-by-1 structure with 5 fields (name, date, bytes, isdir, datenum), where n is the number of entries in the folder. 

wellFileList={};
for i=3:length(imgFiles) % first 2 entries are '.' and '..'
    
    imgName=imgFiles(i).name;
    %disp(imgName);
    st1=regexp(imgName,'\(fld.\d.*\)','once'); % contains 'fld' followed by any character followed by a numeric digit within brackets. need backslash to denote brackets are part of regular exp.
    st2=regexp(imgName,'wv', 'once'); % contains 'wv'

    if st1(1)>5 && st2(1)>8 % confirms to the naming format
        %do the operations
        well=regexp(imgName,'.*(?=\(fld)','match','once'); % anything before the '(fld' holds the well number.
        well=regexprep(well,' - ',''); %removes the ' - ' from the well name.
        %field=regexp(imgName,'(?<=\(fld).\d+.','match','once'); % anything after the '(fld' followed by any character followed by any number of numeric digits followed by any character
        %field=str2num(field);
        wellFileList{end+1}=well;
    else
        disp(imgName);
        disp('file name not in format');
    end
end

uniqWells=unique(wellFileList); % a row cell-array of strings
wellFileCount=cell(length(uniqWells),2);
for i=1:length(uniqWells)
    wellFileCount{i,1}=uniqWells{i};
    wellFileCount{i,2}=0;
end

for i=1:length(uniqWells)
    for j=1:length(wellFileList)
        if strcmp(wellFileList{j},uniqWells{i})
            wellFileCount{i,2}=wellFileCount{i,2}+1;
        end
    end
end

end    


