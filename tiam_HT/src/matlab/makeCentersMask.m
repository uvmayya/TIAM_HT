
function mask = makeCentersMask(initimg,centers)


% makes a mask for initimg of centers (each row a center, [xpos, ypos])

% returns a logical matrix mask

mask = zeros([size(initimg,1),size(initimg,2)]);
for i = 1 : size(centers,1)
	mask(floor(centers(i,1)-2):floor(centers(i,1)+2), floor(centers(i,2)-2):floor(centers(i,2)+2)) = 1;   %%%%%% COULD CRASH NEEDS FIXING !!!!!
end
mask = logical(mask);