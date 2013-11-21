% created by Srinivas Gorur-Shandilya at 19:18 , 18 November 2013. Contact
% me at http://srinivas.gs/contact/
% part of the track3 codebase
function [SeperationDifficulty, rp,posx,posy,area,orientation]=SplitCollidingFlies(CollidingFly,rp,posx,posy,area,orientation,ff,DividingLine,frame,thresh,adjacency)
% find the object to split
mergedfly = CollidingFly(1);
otherfly = CollidingFly(2);
[thisobj] = FindClosestObject2Fly(rp,mergedfly,posx,posy,DividingLine,frame);

cx = round(rp(thisobj).Centroid(1));
cy = round(rp(thisobj).Centroid(2));
% make sure we are cutting it nicely
thisfly = CutImage(ff,[cy cx],75);
disc_sizes = [1:2:6 7 8 9];
SeperationDifficulty=0;
rp2=[];
if min(min(adjacency(CollidingFly,frame-10:frame-1))) == 1
    % flies have been adjacent for a long time, so skip morpholigcal
    % seperation

else
    for k = disc_sizes
        % open the image using a disc
        if ~SeperationDifficulty
            rp2=regionprops(logical(im2bw(imopen(thisfly,strel('disk',k)),thresh)),'Orientation','Centroid','Area','PixelList');
            if length(rp2) == 2
                % check that the sum of the sizes of the two flies is the
                % same
                if abs((sum([rp2.Area])/rp(thisobj).Area-1))<0.5
                    % check that the two objects have approximately the
                    % same area
                    if  abs((rp2(1).Area-rp2(2).Area))/(sum([rp2.Area])) < 0.4
                        % delete the old large object
                        rp(thisobj) = [];
                        % fix the positions of the new objects
                        rp2(1).Centroid(1) = rp2(1).Centroid(1)+cx-75;
                        rp2(2).Centroid(1) = rp2(2).Centroid(1)+cx-75;
                        rp2(1).Centroid(2) = rp2(1).Centroid(2)+cy-75;
                        rp2(2).Centroid(2) = rp2(2).Centroid(2)+cy-75;
                        % fix the pixel lists
                        rp2(1).PixelList(:,1) =  floor(rp2(1).PixelList(:,1) + cx  - 75);
                        rp2(1).PixelList(:,2) =  floor(rp2(1).PixelList(:,2) + cy  - 75);
                        rp2(2).PixelList(:,1) =  floor(rp2(2).PixelList(:,1) + cx  - 75);
                        rp2(2).PixelList(:,2) =  floor(rp2(2).PixelList(:,2) + cy  - 75);
                        SeperationDifficulty = k;
                    end
                end
            else
                rp2 =[];
            end
        end
    end
end        

if SeperationDifficulty ==0 
    % disp('Split failure...trying k-means seperation...')
    % try to seperate them using k-means
    k=5;
    thisfly= (logical(im2bw(imopen(thisfly,strel('disk',k)),thresh)));
    [xk,yk]=ind2sub([151,151],find(thisfly));
    [idx,rp2centroid]=kmeans([xk yk],2);

    % reconstruct a fake regionprops struct
    rp2(1).Area = rp(thisobj).Area/2;
    rp2(2).Area = rp(thisobj).Area/2;
    rp2(1).Centroid(1) = rp2centroid(1,2) + cx - 75;
    rp2(1).Centroid(2) = rp2centroid(1,1) + cy - 75;
    rp2(2).Centroid(1) = rp2centroid(2,2) + cx - 75;
    rp2(2).Centroid(2) = rp2centroid(2,1) + cy - 75;
    rp2(1).PixelList = [xk(idx==1) yk(idx==1)];
    rp2(2).PixelList = [xk(idx==2) yk(idx==2)];
         

    % inherit orientation.
    rp2(1).Orientation = rp(thisobj).Orientation;
    rp2(2).Orientation = rp(thisobj).Orientation;
    SeperationDifficulty = Inf;

end
      

% merge objects
if length(rp2) ~= 2
    beep
    keyboard
end
try
    rp = [rp;rp2];
catch
    try
        rp = [rp;reshape(rp2,2,1)];
    catch
        keyboard
    end

end

% update positions--force assign objects
% assign mergedfly
[thisobj] = FindClosestObject2Fly(rp2,mergedfly,posx,posy,DividingLine,frame);
posx(mergedfly,frame) = rp2(thisobj).Centroid(1);
posy(mergedfly,frame) = rp2(thisobj).Centroid(2);
if isinf(SeperationDifficulty)
    area(mergedfly,frame) = sum([rp2.Area])/2; % areas can't be trusted
else
    area(mergedfly,frame) = rp2(thisobj).Area; 
end
orientation(mergedfly,frame) = -rp2(thisobj).Orientation;

% mark it as assigned
rp2(thisobj).Centroid = [Inf Inf];

% assign otherfly
thisfly=otherfly;
[thisobj] = FindClosestObject2Fly(rp2,thisfly,posx,posy,DividingLine,frame);
posx(thisfly,frame) = rp2(thisobj).Centroid(1);
posy(thisfly,frame) = rp2(thisobj).Centroid(2);
if isinf(SeperationDifficulty)
    area(thisfly,frame) = sum([rp2.Area])/2; % areas can't be trusted
else
    area(thisfly,frame) = rp2(thisobj).Area; 
end
orientation(thisfly,frame) = -rp2(thisobj).Orientation;
% mark it as assigned
rp2(thisobj).Centroid = [Inf Inf];



        
        
