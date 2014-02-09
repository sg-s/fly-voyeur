% matches spots to fly IDs based on position. 
function [spottyflies] = MatchSpots2Flies(ff,posx,posy)

spottyflies = [];
max_dist = 10; % how far away from the object centroid can be spot be located and still be matched to it? 

% detect all spot objects--assume ff is the subtracted image
thresh = graythresh(ff);
l = logical(im2bw(ff,thresh));
spots = regionprops(l,'Centroid','Area');
spot_centroids=reshape([spots.Centroid],2,length(spots));
if isempty(spot_centroids)
    return
end

for i = 1:length(posx)
	% check if there is a spot close to this centroid
	if any(sqrt((posx(i)-spot_centroids(1,:)).^2 + (posy(i) - spot_centroids(2,:)).^2) < max_dist)
		% spot match
		spottyflies = [spottyflies i];
	end

end