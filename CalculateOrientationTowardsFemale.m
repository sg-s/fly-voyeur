% created by Srinivas Gorur-Shandilya at 21:06 , 22 January 2014. Contact me at http://srinivas.gs/contact/
% calculates the sum of frames where the male is looking at the female
function [OrientationTowardsFemale] = CalculateOrientationTowardsFemale(posx,posy,orientation)
% arena 1
o=atan2d((posy(2,:) - posy(1,:)),(posx(2,:) - posx(1,:)));
o1 = o; o2 = o;
for i = 1:length(o)
	o1(i) = AngularDifference(o(i),orientation(1,i));
	o2(i) = AngularDifference(o(i),orientation(2,i));
end
o = min[o1;o2];
