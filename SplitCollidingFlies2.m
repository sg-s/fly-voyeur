% created by Srinivas Gorur-Shandilya at 19:18 , 18 November 2013. Contact
% me at http://srinivas.gs/contact/
% part of the track3 codebase
function [SeperationDifficulty, rp,posx,posy,area,orientation]=SplitCollidingFlies2(ff,SplitThisObject,f1,f2,posx,posy,area,orientation,DividingLine,frame,rp,adjacency,thresh,maskthis)

% new algorithm
% delete all tracking data from flies f1 and f2
posx(f1,frame) =  NaN;
posx(f2,frame) =  NaN;
posy(f1,frame) =  NaN;
posy(f2,frame) =  NaN;
area(f1,frame) = NaN;
area(f2,frame) = NaN;
orientation(f1,frame) = NaN;
orientation(f2,frame) = NaN;

% take object provided and split it
cx = round(rp(SplitThisObject).Centroid(1));
cy = round(rp(SplitThisObject).Centroid(2));
% mask the third fly
for i = 1:length(rp(maskthis).PixelList) % how do i vecotirse this??
    ff(rp(maskthis).PixelList(i,2),rp(maskthis).PixelList(i,1)) = 0;
end

% make sure we are cutting it nicely
thisfly = CutImage(ff,[cy cx],75);
disc_sizes = [1:2:6 7 8 9];
SeperationDifficulty=0;
rp2=[];
if min(min(adjacency([f1 f2],frame-10:frame-1))) == 1
    % flies have been adjacent for a long time, so skip morpholigcal
    % seperation

else
    for k = disc_sizes
        % open the image using a disc
        if ~SeperationDifficulty
            rp2=regionprops(logical(im2bw(imopen(thisfly,strel('disk',k)),thresh)),'Orientation','Centroid','Area','PixelList','MajorAxisLength','MinorAxisLength');
            if length(rp2) == 2
                % check that the sum of the sizes of the two flies is the
                % same
                if abs((sum([rp2.Area])/rp(SplitThisObject).Area-1))<0.5
                    % check that the two objects have approximately the
                    % same area
                    if  abs((rp2(1).Area-rp2(2).Area))/(sum([rp2.Area])) < 0.4
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
    rp2(1).Area = rp(SplitThisObject).Area/2;
    rp2(2).Area = rp(SplitThisObject).Area/2;
    rp2(1).Centroid(1) = rp2centroid(1,2) + cx - 75;
    rp2(1).Centroid(2) = rp2centroid(1,1) + cy - 75;
    rp2(2).Centroid(1) = rp2centroid(2,2) + cx - 75;
    rp2(2).Centroid(2) = rp2centroid(2,1) + cy - 75;
    rp2(1).PixelList = [xk(idx==1) yk(idx==1)];
    rp2(2).PixelList = [xk(idx==2) yk(idx==2)];
         

    % inherit orientation.
    rp2(1).Orientation = rp(SplitThisObject).Orientation;
    rp2(2).Orientation = rp(SplitThisObject).Orientation;
    SeperationDifficulty = Inf;

end
      
% assign halves of split object to f1 and f2. 
% delete old object
rp(SplitThisObject) = [];
% merge objects
if length(rp2) ~= 2
    beep
    error('Split failure')
end
try
    rp = [rp;rp2];
catch
    try
        rp = [rp;reshape(rp2,2,1)];
    catch
        error('Split failure: regions cant be merged')
    end

end

% update positions--force assign objects
% assign f1
[f1obj] = FindClosestObject2Fly(rp2,f1,posx,posy,DividingLine,frame);
posx(f1,frame) = rp2(f1obj).Centroid(1);
posy(f1,frame) = rp2(f1obj).Centroid(2);
if isinf(SeperationDifficulty)
    area(f1,frame) = sum([rp2.Area])/2; % areas can't be trusted
else
    area(f1,frame) = rp2(f1obj).Area; 
end
orientation(f1,frame) = -rp2(f1obj).Orientation;

% mark it as assigned
rp2(f1obj).Centroid = [Inf Inf];

% assign otherfly
[f2obj] = FindClosestObject2Fly(rp2,f2,posx,posy,DividingLine,frame);
posx(f2,frame) = rp2(f2obj).Centroid(1);
posy(f2,frame) = rp2(f2obj).Centroid(2);
if isinf(SeperationDifficulty)
    area(f2,frame) = sum([rp2.Area])/2; % areas can't be trusted
else
    area(f2,frame) = rp2(f2obj).Area; 
end
orientation(f2,frame) = -rp2(f2obj).Orientation;
% mark it as assigned
rp2(f2obj).Centroid = [Inf Inf];

% check that everyhting is OK
if any(isinf(posx(:,frame)))
    disp('infinite distance')
    keyboard
    error('Infinite distance')
end 


        
        
