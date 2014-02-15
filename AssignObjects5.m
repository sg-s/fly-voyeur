% created by Srinivas Gorur-Shandilya at 18:50 , 18 November 2013. Contact
% me at http://srinivas.gs/contact/
% part of the Track4 codebase
% AssignObjects5.m is a re-write of the previous version, where assignation is done on a per-arena basis. 
function [posx,posy,orientation,area,flymissing,collision,MajorAxis,MinorAxis] = AssignObjects5(frame,StartTracking,rp,posx,posy,orientation,area,flymissing,DividingLine,collision,MajorAxis,MinorAxis)

% core parameters:
jump = 100;
n  =size(posx,1);
assigned_objects = NaN(1,n); % keeps track of which objects are assigned to which fly


%% start code

if frame == StartTracking
    % special case, first frame. assume everything OK.
    for i = 1:n
        posx(i,StartTracking) = rp(i).Centroid(1);
        posy(i,StartTracking) = rp(i).Centroid(2);
        orientation(i,StartTracking) = -rp(i).Orientation;
        area(i,StartTracking) = rp(i).Area;
        MajorAxis(i,StartTracking) = rp(i).MajorAxisLength;
        MinorAxis(i,StartTracking) = rp(i).MinorAxisLength;
    end
    return
    
end

% general case
% this has two different cases: when there are more objects than
% flies, it goes through each fly and assigns the nearest object.
% if not, it goes through each object and assigns it to the nearest
% fly
% now, we do it in a per-arena manner.

for arena = 1:2
    % figure out which objects are in this arena
    regionx  = [rp.Centroid];
    regionx = regionx(1:2:end);
    allflies = [2*arena 2*arena-1];

    if arena==1
        rp_thisarena = rp(regionx<DividingLine);
    else
        rp_thisarena = rp(regionx>DividingLine);
        
    end

    if length(rp_thisarena) < n/2
        % fewer objects than flies

        for j = 1:length(rp_thisarena)
            temp = [rp_thisarena(j).Centroid; posx(:,frame-1) posy(:,frame-1) ];

            % remove already assigned flies
            temp(logical([0;~isnan(posx(:,frame))]),:) = Inf;

            d = squareform(pdist(temp));
            if ~isempty(d)
                d = d(1,2:end);
            end
            [step,thisfly] = min(d); 
            if step < jump
                % assign this fly to this object
                posx(thisfly,frame) = rp_thisarena(j).Centroid(1);
                posy(thisfly,frame) = rp_thisarena(j).Centroid(2);
                area(thisfly,frame) = rp_thisarena(j).Area;
                orientation(thisfly,frame) = -rp_thisarena(j).Orientation;
                assigned_objects(thisfly) = j;
                MajorAxis(thisfly,frame) = rp_thisarena(j).MajorAxisLength;
                MinorAxis(thisfly,frame) = rp_thisarena(j).MinorAxisLength;

            elseif isinf(step)
            % fly is jumping, probably

            elseif step > jump
                if flymissing(thisfly,frame-1) 
                    % fly was missing last frame, so it's OK
                    posx(thisfly,frame) = rp_thisarena(j).Centroid(1);
                    posy(thisfly,frame) = rp_thisarena(j).Centroid(2);
                    area(thisfly,frame) = rp_thisarena(j).Area;
                    MajorAxis(thisfly,frame) = rp_thisarena(j).MajorAxisLength;
                    MinorAxis(thisfly,frame) = rp_thisarena(j).MinorAxisLength;
                    orientation(thisfly,frame) = -rp_thisarena(j).Orientation;
                    assigned_objects(thisfly) = j;
                else
                    % this is a pathological case. skip it -- its
                    % too messy otherwise
                end

            end
        
        end

    else
        % disp('at least as many objects as flies')
        % assign flies to objects
        for i = allflies
            o_centroids = [];
            for j = 1:length(rp_thisarena)
                o_centroids=[o_centroids; rp_thisarena(j).Centroid]; % rearranging all object centroids into a matrix
            end
            temp = [posx(i,frame-1) posy(i,frame-1); o_centroids];
            d = squareform(pdist(temp));
            if ~isempty(d)
                d = d(1,2:end);
            else
                % something is wrong. skip this frame
                posx(i,frame) = posx(i,frame-1);
                posy(i,frame) = posy(i,frame-1);
                area(i,frame) = 0;
                flymissing(i,frame) = 1;
                %break
            end


            [step,thisobj] = min(d);
            if step < jump
                % assign this object to this fly
                posx(i,frame) = rp_thisarena(thisobj).Centroid(1);
                posy(i,frame) = rp_thisarena(thisobj).Centroid(2);
                area(i,frame) = rp_thisarena(thisobj).Area;
                orientation(i,frame) = -rp_thisarena(thisobj).Orientation;
                MajorAxis(i,frame) = rp_thisarena(thisobj).MajorAxisLength;
                MinorAxis(i,frame) = rp_thisarena(thisobj).MinorAxisLength;
                % mark it as assigned
                rp_thisarena(thisobj).Centroid = [Inf Inf];
                assigned_objects(i) = thisobj;

            elseif isinf(step)
                % if this is a missing fly, keep going
                % this means the fly has just gone missing, and other
                % flies elsewhere in other arenas are segmented
                posx(i,frame) = posx(i,frame-1);
                posy(i,frame) = posy(i,frame-1);
                area(i,frame) = 0;
                flymissing(i,frame) = 1;

            else
                % step exceeds bounds
                % if this is a missing fly, OK it
                if flymissing(i,frame-1)
                    % assign this object to this fly
                    posx(i,frame) = rp_thisarena(thisobj).Centroid(1);
                    posy(i,frame) = rp_thisarena(thisobj).Centroid(2);
                    area(i,frame) = rp_thisarena(thisobj).Area;
                    orientation(i,frame) = -rp_thisarena(thisobj).Orientation;
                    MajorAxis(i,frame) = rp_thisarena(thisobj).MajorAxisLength;
                    MinorAxis(i,frame) = rp_thisarena(thisobj).MinorAxisLength;
                    % mark it as assigned
                    rp_thisarena(thisobj).Centroid = [Inf Inf];
                    assigned_objects(i) = thisobj;
                elseif any(pdist([posx(:,frame-1) posy(:,frame-1)])<40)
                    % hmm. flies were suspciciously close in the previous
                    % frame. that's probably a wrong assignment of multiple
                    % flies to the same object
                    % so let's OK this one.
                    posx(i,frame) = rp_thisarena(thisobj).Centroid(1);
                    posy(i,frame) = rp_thisarena(thisobj).Centroid(2);
                    area(i,frame) = rp_thisarena(thisobj).Area;
                    orientation(i,frame) = -rp_thisarena(thisobj).Orientation;
                    MajorAxis(i,frame) = rp_thisarena(thisobj).MajorAxisLength;
                    MinorAxis(i,frame) = rp_thisarena(thisobj).MinorAxisLength;
                    % mark it as assigned
                    rp_thisarena(thisobj).Centroid = [Inf Inf];
                    assigned_objects(i) = thisobj;
                else

                    % fly goes missing now
                    posx(i,frame) = posx(i,frame-1);
                    posy(i,frame) = posy(i,frame-1);
                    area(i,frame) = 0;
                    flymissing(i,frame) = 1;

                end
            end

        end

    end

end

% all objects assigned
% now any flies without assignations are to be declared
% missing
for i = 1:n
    if isnan(posx(i,frame))
        posx(i,frame) = posx(i,frame-1);
        posy(i,frame) = posy(i,frame-1);
        area(i,frame) = area(i,frame-1);
        flymissing(i,frame) = 1;
    end
end




for i = 1:n
    % collision check
    % if it was in a collision in the last frame and is misisng
    % now, then it's in a collision now
    if collision(i,frame-1) && flymissing(i,frame)
        collision(i,frame) =1;
    end

    % if fly is close to another fly, then it is colliding with
    % it
    temp = [posx(i,frame);posy(i,frame)];
    temp =  pdist2(temp',[posx(:,frame) posy(:,frame)]);
    if min(nonzeros(temp)) < 50
        collision(i,frame) = 1;
    end 

end


% safety check

if any(isinf(posx(:,frame)))
    disp('infinite distance')
    error('Infinite distance')
end 


% safety check
leftflies = find(posx(:,frame) < DividingLine);
rightflies = find(posx(:,frame) > DividingLine);
if length(leftflies) ~= n/2

    error('265') 
end
if length(rightflies) ~= n/2
    
  error('2625') 
end
