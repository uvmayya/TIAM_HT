function [well,field]=getWellFieldInfo(imgName)
% returns well and field designations as strings
% the file names need to be in the inCell Data format.
% Example file name: E - 2(fld 2 wv Blue - FITC).tif

idx1=regexp(imgName,'\(fld.\d.*\)','once'); % contains 'fld' followed by any character followed by a numeric digit within brackets. need backslash to denote brackets are part of regular exp.
idx2=regexp(imgName,'wv', 'once'); % contains 'wv'

if idx1(1)>5 && idx2(1)>8 % confirms to the naming format
    %do the operations
    well=regexp(imgName,'.*(?=\(fld)','match','once'); % anything before the '(fld' holds the well number.
    well=regexprep(well,' - ',''); %removes the ' - ' from the well name.
    field=regexp(imgName,'(?<=\(fld).\d+.','match','once'); % anything after the '(fld' followed by any character followed by any number of numeric digits followed by any character
    field=str2num(field);
else
    well='';
    field=[];
    disp('file name not in format');
end

end