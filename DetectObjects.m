function [rp] = DetectObjects(bb,ff,thresh)
% part of the Track3 codebase
if bb
    rp =[];
    l = logical(im2bw(ff,thresh));
    rp = regionprops(l,'Orientation','Centroid','Area','PixelList','BoundingBox');
else
    rp =[];
    l = logical(im2bw(ff,thresh));
    rp = regionprops(l,'Orientation','Centroid','Area','PixelList');
end