function [threshNorm,IDX,sep,thresh] = otsu2class(I)

%%OTSU Global image thresholding/segmentation using Otsu's method into 2 classes.
%   the original code by Damien Garcia (function named otsu.m)
%   %   -- Damien Garcia -- 2007/08, revised 2010/03
%   Visit my <a
%   href="matlab:web('http://www.biomecardio.com/matlab/otsu.html')">website</a> for more details about OTSU
%
%   Reference:
%   ---------
%   Otsu N, <a href="matlab:web('http://dx.doi.org/doi:10.1109/TSMC.1979.4310076')">A Threshold Selection Method from Gray-Level Histograms</a>,
%   IEEE Trans. Syst. Man Cybern. 9:62-66;1979

%% Modifications
%   only handles 2 clases (i.e. thresholding into 2 classes)
%   returns the threshold value for further use elsewhere.
%
%% Usage
%   threshNorm = otsu2class(I) returns the min-max normalized (between 0 and 1) threshold intensity value (also referred as level)
%
%   [threshNorm,IDX] = otsu2class(I) also returns an array IDX containing the cluster
%   indices (1 for background 2 for foreground object) of each point. Zero values are assigned to
%   non-finite (NaN or Inf) pixels.
%
%   [threshNorm,IDX,sep] = otsu2class(I) also returns the value (sep) of the separability
%   criterion within the range [0 1]. Zero is obtained only with data
%   having less than 2 values, whereas one (optimal value) is obtained only
%   when the image as 2 values.
%
%   [threshNorm,IDX,sep,thresh] = otsu2class(I) also returns the actual threshold intensity value
%   
%   Notes:
%   If I is an RGB image, a Karhunen-Loeve transform is first performed on
%   the three R,G,B channels. The segmentation is then carried out on the
%   image component that contains most of the energy.
%

%% Initial checks   
narginchk(1,1)

% Check if is the input is an RGB image
isRGB = isrgb(I);

assert(isRGB | ndims(I)==2,...
    'The input must be a 2-D array or an RGB image.')

I = single(I);

%% Perform a KLT if isRGB, and keep the component of highest energy
if isRGB
    sizI = size(I);
    I = reshape(I,[],3);
    [V,D] = eig(cov(I));
    [tmp,c] = max(diag(D));
    I = reshape(I*V(:,c),sizI(1:2)); % component with the highest energy
end

%% Convert to 256 levels after min-max normalizations 
minVal=min(I(:));
I = I-min(I(:));
corrMaxVal=max(I(:));
I = round(I/max(I(:))*255);


%% Probability distribution
unI = sort(unique(I)); % a vector output
nbins = min(length(unI),256);
if nbins==2 % if we have only 2 unique values in the image
    IDX = ones(size(I));
    for i = 1:nbins, IDX(I==unI(i)) = i; end
    sep = 1;
    threshNorm=max(unI)/255; % to be between 0 and 1
    thresh=(max(unI)*corrMaxVal/255)+minVal; % converting back to original pixel Values
    return
elseif nbins<2
    IDX = NaN(size(I));
    sep = 0;
    threshNorm=0;
    thresh=0; % whole image thresholded (i.e. no threshold)
    return
elseif nbins<256
    [histo,pixval] = hist(I(:),unI); % though unI is a vector, it works as per the 'xvalues' options in the hist function
else
    [histo,pixval] = hist(I(:),256);
end
P = histo/sum(histo);
clear unI

%% Zeroth- and first-order cumulative moments
w = cumsum(P);
mu = cumsum((1:nbins).*P);

%% Maximal sigmaB^2 and Segmented image
    sigma2B =...
        (mu(end)*w(2:end-1)-mu(2:end-1)).^2./w(2:end-1)./(1-w(2:end-1));
    [maxsig,k] = max(sigma2B);
    
    % segmented image
    IDX = ones(size(I));
    IDX(I>=pixval(k+1)) = 2;
    
    % separability criterion
    sep = maxsig/sum(((1:nbins)-mu(end)).^2.*P);
    
    IDX(~isfinite(I)) = 0;
    
    threshNorm=pixval(k)/nbins; % to be between 0 and 1
    thresh=(pixval(k)*corrMaxVal/nbins)+minVal; % converting back to original pixel Values
    
end

function isRGB = isrgb(A)
%% --- Do we have an RGB image?
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


