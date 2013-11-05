% computes abslute angular distance between two angles in degrees
function [d] = AngularDifference(a,b)
a = mod(a,360);
b = mod(b,360);
d1=abs(a-b);
d2 = abs(360-d1);
d = min([d1 d2]);
