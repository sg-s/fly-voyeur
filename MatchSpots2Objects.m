% created by Srinivas Gorur-Shandilya at 20:22 , 04 December 2013. Contact me at http://srinivas.gs/contact/
% this function matches spots in the image ff (to be determined) to objects, already calcualted by region props, in the structure rp
function [objectIDs] = MatchSpots2Objects(ff,rp)

objectIDs = [];
max_dist = 6; % how far away from the object centroid can be spot be located and still be matched to it? 

% detect all spot objects--assume ff is the subtracted image
thresh = graythresh(ff);
l = logical(im2bw(ff,thresh));
spots = regionprops(l,'Centroid','Area');
spot_centroids=reshape([spots.Centroid],length(spots),2);
if size(spot_centroids,2)>size(spot_centroids,1)
    spot_centroids = spot_centroids';
end
for i = 1:length(rp)
	% check if there is a spot close to this centroid
	if any(sqrt((rp(i).Centroid(1)-spot_centroids(1,:)).^2 + (rp(i).Centroid(2) - spot_centroids(2,:)).^2) < max_dist)
		% spot match
		objectIDs = [objectIDs i];
	end

end
