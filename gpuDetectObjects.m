function [rp] = gpuDetectObjects(bb,ff,thresh)
% part of the Track3 codebase
if bb
    rp =[];
    l = ff>255*thresh;

    rp = regionprops(l,'Orientation','Centroid','Area','PixelList','BoundingBox');
else
    rp =[];
    l = ff>255*thresh;
    rp = regionprops(l,'Orientation','Centroid','Area','PixelList','MajorAxisLength','MinorAxisLength');
end