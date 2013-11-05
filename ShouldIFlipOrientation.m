% ShouldIFlipOrientation.m
% determines if the orientation determined by regionprops of an image
% containing a fly is right, or exactly 180 degress off
% this works by fitting two ellipses to the image, one large for the body
% and one small for the head, in both orientations and determining which is
% the better fit
function flip = ShouldIFlipOrientation(thisfly,rp,x,y)
% params
a1 = rp.MajorAxisLength/6; % foci for major
a2 = 0; % ellipse
% find the major axis
if abs(rp.Orientation) > 45
    yy  = 1:100;
    xx = cotd(rp.Orientation).*(yy) + 50;
else
    xx  = 1:100;
    yy = tand(rp.Orientation).*(xx) + 50;
end
centroid = [50 50];
if abs(rp.Orientation) > 45
    % for the major ellipse, pick the foci
    dis = (pdist2(centroid,[xx;yy]')-a1);
    dis = floor(abs(dis));
    thesepoints=   find(dis==0);
    thesepoints = thesepoints(1);
    dis = (pdist2(centroid,[xx;yy]')-a2);
    dis = floor(abs(dis));
    thesepoints2=   find(dis==0);
    thesepoints = [thesepoints thesepoints2(1)];
else
    m = tand(rp.Orientation);
    d = sqrt(10000 + 4*(1+m*m)*a1*a1);
    Bodyx1(1) = (100+d)/(2*(1+m*m));
    Bodyx1(2) = (100-d)/(2*(1+m*m));
    Bodyy1 = Bodyx1.*m + 50;
end
keyboard

% for the minor ellipse, pick the foci
% make a logical amtrix of the rasterised ellipses
% turn it around
% compute the correlations
keyboard

