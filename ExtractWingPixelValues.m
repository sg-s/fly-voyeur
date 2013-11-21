function [left,right,leftw,rightw] = ExtractWingPixelValues(thisfly,ori)
c2b = 25;
left(1) = round(50 - c2b*sind(ori));
left(2) = round(50 + c2b*cosd(ori));
right(1) = round(50 + c2b*sind(ori));
right(2) = round(50 - c2b*cosd(ori));
% grab pixel values around these 2 points
wingsize = 3;
leftw=thisfly(left(2)-wingsize:left(2)+wingsize,left(1)-wingsize:left(1)+wingsize);
rightw=thisfly(right(2)-wingsize:right(2)+wingsize,right(1)-wingsize:right(1)+wingsize);
    