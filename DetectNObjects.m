% detect n objects in the given frame. 
% uses a close operation on the image with successively bigger
% structural elements to guarantee a return of n  objects
% this function replaces many functions in one fell swoop:
% find objects, collision detection, etc. 
function [rp,s] = DetectNObjects(ff,n,thresh)
s = 1;
ffc = imclose(ff,strel('disk',s));
l = logical(im2bw(ffc,thresh));
rp = regionprops(l,'Orientation','Centroid','Area','PixelList','BoundingBox');
if length(rp)  > n
	while length(rp) > n
		s = s+2;

		ffc = imclose(ff,strel('disk',s));
		l = logical(im2bw(ffc,thresh));
		rp = regionprops(l,'Orientation','Centroid','Area','PixelList','BoundingBox');
	end
	
end

	
	


