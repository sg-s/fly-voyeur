function [thisobj] = FindClosestObject2Fly(rp,thisfly,posx,posy,DividingLine,frame)
% finds the closest object among a list of regions to a fly
o_centroids = [];
for j = 1:length(rp)
    o_centroids=[o_centroids; rp(j).Centroid]; % rearranging all object centroids into a matrix
end
temp = [posx(thisfly,frame-1) posy(thisfly,frame-1); o_centroids];

% figure out if fly is on left or right arena
if posx(thisfly,frame-1) < DividingLine
    % on left
    temp(temp(:,1) > DividingLine,:) = Inf;
else
    temp(temp(:,1) < DividingLine,:) = Inf;
end

% find closest object to ith fly
d = squareform(pdist(temp));
d = d(1,2:end);
[~,thisobj] = min(d);
