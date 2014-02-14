% created by Srinivas Gorur-Shandilya at 20:14 , 13 February 2014. Contact me at http://srinivas.gs/contact/
% part of Track4 code ase
% flips an orientaiton from 0 to 180 or 0 to -180, preserving sign.
function [o] = FlipOrientation(o)
if o < 0
    o = o + 180;
else
    o = o - 180;
end