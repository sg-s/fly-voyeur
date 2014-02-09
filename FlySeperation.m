% finds the separation between two flies.
% this is not the distance from the centres of each fly, but the closest distance between them
function [d] = FlySeperation(i,otherfly,posx,posy,MajorAxis,MinorAxis,orientation);
% for each fly, we cosntruct four points, corresponding to the limits of the ellipse.
head1(1) = cosd(orientation(i))*(MajorAxis(i)/2) + posx(i);
head1(2) = sind(orientation(i))*(MajorAxis(i)/2) + posy(i);
tail1(1) = -cosd(orientation(i))*(MajorAxis(i)/2) + posx(i);
tail1(2) = -sind(orientation(i))*(MajorAxis(i)/2) + posy(i);

left1(1) = -sind(orientation(i))*(MinorAxis(i)/2) + posx(i);
left1(2) = cosd(orientation(i))*(MinorAxis(i)/2) + posy(i);
right1(1) = sind(orientation(i))*(MinorAxis(i)/2) + posx(i);
right1(2) = -cosd(orientation(i))*(MinorAxis(i)/2) + posy(i);


head2(1) = cosd(orientation(otherfly))*(MajorAxis(otherfly)/2) + posx(otherfly);
head2(2) = sind(orientation(otherfly))*(MajorAxis(otherfly)/2) + posy(otherfly);
tail2(1) = -cosd(orientation(otherfly))*(MajorAxis(otherfly)/2) + posx(otherfly);
tail2(2) = -sind(orientation(otherfly))*(MajorAxis(otherfly)/2) + posy(otherfly);

left2(1) = -sind(orientation(otherfly))*(MinorAxis(otherfly)/2) + posx(otherfly);
left2(2) = cosd(orientation(otherfly))*(MinorAxis(otherfly)/2) + posy(otherfly);
right2(1) = sind(orientation(otherfly))*(MinorAxis(otherfly)/2) + posx(otherfly);
right2(2) = -cosd(orientation(otherfly))*(MinorAxis(otherfly)/2) + posy(otherfly);

d = min(min(pdist2([head1;left1;right1;tail1], [head2;left2;right2;tail2])));