% part of Track4 codebase.
% removes all other flies apart from the one specified by its centroid from the image. 
function [ff] = RemoveAllOtherFlies(ff,posx,posy,rp);

% find the object corresponding to this fly
[thisobj] = FindClosestObject2Point(rp,posx,posy);

% delete all other objects
for j = setdiff(1:length(rp),thisobj)
	for i = 1:length(rp(j).PixelList) % how do i vectorise this??
    	ff(rp(j).PixelList(i,2),rp(j).PixelList(i,1)) = 0;
	end
end