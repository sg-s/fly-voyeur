% CutImage.m
% cuts a small part of an image out a bigger image.
% if the requested portion is too large, cut image pads the image
function [SmallImage] = CutImage(BigImage,centre,cutsize)
cx = round(centre(2));
cy = round(centre(1));
% make sure we are cutting it nicely
[h,l] = size(BigImage);
cutOK =  [(cy-cutsize) (h-cy-74) (cx-cutsize) (l-cx-74)]>0;
ff2 = BigImage; 
if any(~cutOK)
    % just pad everything with zeros, then cut out the image, 
      
    ff2 = vertcat(zeros(cutsize,l),ff2);
    ff2 = vertcat(ff2,zeros(cutsize,l));
    ff2 = [zeros(h+2*cutsize,cutsize) ff2 zeros(h+2*cutsize,cutsize)];
    SmallImage = ff2(cy:cy+2*cutsize,cx:cx+2*cutsize);
else
    SmallImage = BigImage(cy-cutsize:cy+cutsize,cx-cutsize:cx+cutsize);
end
