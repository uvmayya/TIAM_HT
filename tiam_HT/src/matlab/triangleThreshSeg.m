function [level,IDX]=triangleThreshSeg(I)
% Thresholding and segmentation of an image by the Triangle algorithm
%     Triangle algorithm
%     This technique is due to Zack (Zack GW, Rogers WE, Latt SA (1977), 
%     "Automatic measurement of sister chromatid exchange frequency", 
%     J. Histochem. Cytochem. 25 (7): 74153, )
%     A line is constructed between the maximum of the histogram at 
%     (b) and the lowest (or highest depending on context) value (a) in the 
%     histogram. The distance L normal to the line and between the line and 
%     the histogram h[b] is computed for all values from a to b. The level
%     where the distance between the histogram and the line is maximal is the 
%     threshold value (level). This technique is particularly effective 
%     when the object pixels produce a weak peak in the histogram.

%     Use Triangle approach to compute threshold (level) based on a
%     1D histogram (lehisto). num_bins levels gray image. 

% The original code by
%   Function named triangle_th.m
%   http://uk.mathworks.com/matlabcentral/fileexchange/28047-gray-image-thresholding-using-the-triangle-method
%   Dr B. Panneton, June, 2010
%   Agriculture and Agri-Food Canada
%   St-Jean-sur-Richelieu, Qc, Canad
%   bernard.panneton@agr.gc.ca

% Limitation as per the original author
%   There are a couple of assumptions that can change the end result. 
%   One is that the histogram has one tail longer than the other and that the 
%   threshold has to be on the long tail side. The other is the definition of 
%   the end point of a histogram tail. In the code, this is set to 10000 (i.e. 
%   tails end when there are less than 10000 pixels in the corresponding 
%   histogram bin). Depending on the size of the image, this might not be an
%   optimum choice.

% Modifications 
%   Takes gray image as input instead of 
%         lehisto :   histogram of the gray level image
%         num_bins:   number of bins (e.g. gray levels)
%   Output is a segmented image IDX (index 2 for foreground and 1 for background) along with 
%         level   :   threshold value in the range [0 1];
%   
%   RGB image is not considered (code for checking borrowed from otsu2class).
%   Histogram is constructed as in otsu2class.m (forces it to be 8-bit if more)
%   Histogram ending definition is changed. It is now made based on the size of the image. 
%   (earlier it was somewhat arbitrary: h/10000 in line 98).
%   Rewrote, from scratch, the entire calculation of distance between the line and the point 
%   in consideration due to recognized and possibly additional unrecognized mistakes in the previous formulae
%   Made corrections to the use of lehisto as it is generated by hist and
%   not input as a column vector.
%   actual pixel value instead of bin value is returned

% Initial checks   
narginchk(1,1)

% Check if is the input is an RGB image
isRGB = isrgb(I);

assert(isRGB | ndims(I)==2,...
    'The input must be a 2-D array or an RGB image.')

I = single(I);

% Return if RGB
if isRGB
    level=0;
    seg=ones(size(I));
end

% Convert to 256 levels after min-max normalizations 
minVal=min(I(:));
I = I-min(I(:));
corrMaxVal=max(I(:));
I = round(I/max(I(:))*255);

% Histogram distribution
unI = sort(unique(I)); % a vector output
num_bins = min(length(unI),256);
if num_bins==2 % if we have only 2 unique values in the image
    IDX = ones(size(I));
    for i = 1:num_bins, IDX(I==unI(i)) = i; end
    level=max(unI)/255; % to be between 0 and 1
    thresh=(max(unI)*corrMaxVal/255)+minVal; % converting back to original pixel Values
    return
elseif num_bins<2
    IDX = ones(size(I));
    level=0;
    thresh=0; % whole image thresholded (i.e. no threshold)
    return
elseif num_bins<256
    [lehisto,pixval] = hist(I(:),unI); % though unI is a vector, it works as per the 'xvalues' options in the hist function
    % using a vector input for second parameter allows uneven binning 
else
    [lehisto,pixval] = hist(I(:),256); % row vector outputs for both lehisto and pixval
end


%   Find maximum of histogram and its location along the x axis
    [h,xmax]=max(lehisto);
    xmax=round(mean(xmax));   %can have more than a single value!
    h=lehisto(xmax);
        
%   Find location of first and last non-zero values.
%   Values < h/(2*max(size(I))) are considered zeros.
    indi=find( lehisto > h/(2*max(size(I))) );
    fnz=indi(1);
    lnz=indi(end);
    %disp(fnz); disp(lnz); disp(xmax);

%   Pick side as side with longer tail. Assume one tail is longer.
    lspan=xmax-fnz;
    rspan=lnz-xmax;
    if rspan>lspan  % then flip lehisto; this is done to match the standard case discussed in the original work (i.e. triangle to the left of the major peak)
        lehisto=fliplr(lehisto); % lehisto originally is a row vector which is reversed because of fliplr
        a=num_bins-lnz+1; 
        b=num_bins-xmax+1; 
        isflip=1;
    else
        isflip=0;
        a=fnz;
        b=xmax;
    end
    %plot(lehisto);
    %disp(h); disp(a); disp(b); %disp(num_bins);
    
%   Compute distances
    x0=a:b; % row vector
    %disp(x0);
    y0=lehisto(x0); % should return a row vector 
    y1=lehisto(a);
    %disp(lehisto);
    denom=realsqrt((b-a)^2 + (h-y1)^2);
    d=abs( ((b-a)*(y1-y0))-((a-x0)*(h-y1)) ) /denom;
    % formula from http://mathworld.wolfram.com/Point-LineDistance2-Dimensional.html (eq 14)
    % x1,y1 is a,lehisto(a) and x2,y2 is b,h in this formula; which define the line based on the two vertices of the triangle
    % x0,y0 define the points from which distance needs to be calculated

%   Obtain threshold as the location of maximum distance d.    
    %bin=find(d==max(d)); %disp(d); %there could be more than one max value of d.
    %bin=a+round(mean(bin)); 
    bin=a+find(d==max(d),1,'last'); % takes the last instance of max value of d; earlier I was taking the mean of all max value bins
    
%   Flip back if necessary
    if isflip
        bin=num_bins-bin+1;
    end
    %disp(bin);
    
    if bin<1, bin=1; end % to make sure a real positive integer is returned in spurious cases.
    % ideally bin<1 should never happen as per the above calculations, but something weird is causing this in some cases.
    
    IDX = ones(size(I));
    IDX(~isfinite(I)) = 0; % to remove NaN values
    IDX(I>pixval(bin)) = 2; % pixel value associated with the bin
    level=pixval(bin)/num_bins; % to be between 0 and 1
    
    %save('trouble','lehisto','bin','d','a','b','h','x0','y0');
 
end            
    
    

function isRGB = isrgb(A)
% --- Do we have an RGB image?    
% RGB images can be only uint8, uint16, single, or double
isRGB = ndims(A)==3 && (isfloat(A) || isa(A,'uint8') || isa(A,'uint16'));
% ---- Adapted from the obsolete function ISRGB ----
if isRGB && isfloat(A)
    % At first, just test a small chunk to get a possible quick negative
    mm = size(A,1);
    nn = size(A,2);
    chunk = A(1:min(mm,10),1:min(nn,10),:);
    isRGB = (min(chunk(:))>=0 && max(chunk(:))<=1);
    % If the chunk is an RGB image, test the whole image
    if isRGB, isRGB = (min(A(:))>=0 && max(A(:))<=1); end
end
end