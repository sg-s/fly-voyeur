% created by Srinivas Gorur-Shandilya at 18:50 , 18 November 2013. Contact
% me at http://srinivas.gs/contact/
% part of the Track3 codebase
% AssignObjects4.m is a modification to the previous version, now with better orientation detection based on wing positions. 
function [posx,posy,orientation,area,flymissing,collision,MajorAxis,MinorAxis] = AssignObjects4(frame,StartTracking,rp,posx,posy,orientation,area,flymissing,DividingLine,collision,MajorAxis,MinorAxis)

% core parameters:
jump = 100;
n  =size(posx,1);
allflies=1:n;
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
if length(rp) < n
    % more flies than objects. some flies missing/colliding
    % assign objects to flies
    for j = 1:length(rp)
        j
        flymissing(:,frame)
        keyboard

        temp = [rp(j).Centroid; posx(:,frame-1) posy(:,frame-1) ];

        % figure out if fly is on left or right arena
        if rp(j).Centroid(1) < DividingLine
            % on left
            temp(temp(:,1) > DividingLine,:) = Inf;
        else
            temp(temp(:,1) < DividingLine,:) = Inf;
        end

        % remove already assigned flies
        temp(logical([0;~isnan(posx(:,frame))]),:) = Inf;

        d = squareform(pdist(temp));
        if ~isempty(d)
            d = d(1,2:end);
        else
            error
            % something is wrong. can't assign this object to
            % any fly. what do i do? who's flying this thing?

        end
        [step,thisfly] = min(d); 
        if step < jump
            % assign this fly to this object
            posx(thisfly,frame) = rp(j).Centroid(1);
            posy(thisfly,frame) = rp(j).Centroid(2);
            area(thisfly,frame) = rp(j).Area;
            orientation(thisfly,frame) = -rp(j).Orientation;
            assigned_objects(thisfly) = j;
            MajorAxis(thisfly,frame) = rp(j).MajorAxisLength;
            MinorAxis(thisfly,frame) = rp(j).MinorAxisLength;

        elseif isinf(step)
            % fly is jumping, probably

            % 
        elseif step > jump
            if flymissing(thisfly,frame-1) 
                % fly was missing last frame, so it's OK
                posx(thisfly,frame) = rp(j).Centroid(1);
                posy(thisfly,frame) = rp(j).Centroid(2);
                area(thisfly,frame) = rp(j).Area;
                MajorAxis(thisfly,frame) = rp(j).MajorAxisLength;
                MinorAxis(thisfly,frame) = rp(j).MinorAxisLength;
                orientation(thisfly,frame) = -rp(j).Orientation;
                assigned_objects(thisfly) = j;
            else
                % this is a pathological case. skip it -- its
                % too messy otherwise
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

    
else
    %% at least as many objects as flies
    % assign flies to objects
    
    for i = [allflies(flymissing(:,frame-1)==0) allflies(flymissing(:,frame-1)==1)]  % this prioritises OK flies
        o_centroids = [];
        for j = 1:length(rp)
            o_centroids=[o_centroids; rp(j).Centroid]; % rearranging all object centroids into a matrix
        end
        temp = [posx(i,frame-1) posy(i,frame-1); o_centroids];

        % figure out if fly is on left or right arena
        if posx(i,frame-1) < DividingLine
            % on left
            temp(temp(:,1) > DividingLine,:) = Inf;
        else
            temp(temp(:,1) < DividingLine,:) = Inf;
        end

        % find closest object to ith fly
        d = squareform(pdist(temp));
        if ~isempty(d)
            d = d(1,2:end);
        else
            % something is wrong. skip this frame
            posx(i,frame) = posx(i,frame-1);
            posy(i,frame) = posy(i,frame-1);
            area(i,frame) = 0;
            flymissing(i,frame) = 1;
            break
        end
        
        [step,thisobj] = min(d);
        if step < jump
            % assign this object to this fly
            posx(i,frame) = rp(thisobj).Centroid(1);
            posy(i,frame) = rp(thisobj).Centroid(2);
            area(i,frame) = rp(thisobj).Area;
            orientation(i,frame) = -rp(thisobj).Orientation;
            MajorAxis(i,frame) = rp(thisobj).MajorAxisLength;
            MinorAxis(i,frame) = rp(thisobj).MinorAxisLength;
            % mark it as assigned
            rp(thisobj).Centroid = [Inf Inf];
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
                posx(i,frame) = rp(thisobj).Centroid(1);
                posy(i,frame) = rp(thisobj).Centroid(2);
                area(i,frame) = rp(thisobj).Area;
                orientation(i,frame) = -rp(thisobj).Orientation;
                MajorAxis(i,frame) = rp(thisobj).MajorAxisLength;
                MinorAxis(i,frame) = rp(thisobj).MinorAxisLength;
                % mark it as assigned
                rp(thisobj).Centroid = [Inf Inf];
                assigned_objects(i) = thisobj;
            elseif any(pdist([posx(:,frame-1) posy(:,frame-1)])<40)
                % hmm. flies were suspciciously close in the previous
                % frame. that's probably a wrong assignment of multiple
                % flies to the same object
                % so let's OK this one.
                posx(i,frame) = rp(thisobj).Centroid(1);
                posy(i,frame) = rp(thisobj).Centroid(2);
                area(i,frame) = rp(thisobj).Area;
                orientation(i,frame) = -rp(thisobj).Orientation;
                MajorAxis(i,frame) = rp(thisobj).MajorAxisLength;
                MinorAxis(i,frame) = rp(thisobj).MinorAxisLength;
                % mark it as assigned
                rp(thisobj).Centroid = [Inf Inf];
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
