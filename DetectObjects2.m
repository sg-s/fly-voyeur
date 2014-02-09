function [rp] = DetectObjects2(bb,ff)
% part of the Track4 codebase
% does not thresh, only works with logical arrays
if bb
    rp =[];
    rp = regionprops(ff,'Orientation','Centroid','Area','PixelList','BoundingBox');
else
    rp =[];
    rp = regionprops(ff,'Orientation','Centroid','Area','PixelList');
end