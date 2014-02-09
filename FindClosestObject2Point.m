function [thisobj] = FindClosestObject2Point(rp,posx,posy)
% finds the closest object among a list of regions to a fly
o_centroids = [];
for j = 1:length(rp)
    o_centroids=[o_centroids; rp(j).Centroid]; % rearranging all object centroids into a matrix
end
temp = [posx posy; o_centroids];

% find closest object to ith fly
d = squareform(pdist(temp));
d = d(1,2:end);
[~,thisobj] = min(d);
