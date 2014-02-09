% first dilate the image with a disk with size a
% then erode it with a disk with size b
% created by Srinivas Gorur-Shandilya at 18:48 , 09 December 2013. Contact me at http://srinivas.gs/contact/
function [ff] = imclose2(ff,a,b)
ff = imerode(imdilate(ff,strel('disk',a)),strel('disk',b));
