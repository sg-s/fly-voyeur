% return trajectories
% Track.m
% this is the actual engine of the tracking code
% this uses some metadata manually entereed about each movie file to
% process movies. this is meant to be run in the background, or when user
% attention is not required. 
% created by Srinivas Gorur-Shandilya at 19:56 , 29 August 2013. Contact me
% at http://srinivas.gs/contact/
function [] = Track2Restored(v,StartFromHere)
%% global params
min_area = 400;
jump = 100;
max_area = 1450; 
DividingLine= [];
LeftStart = [];
RightStart = [];
StartTracking  =[];
StopTracking  =[];
n = [];
narenas=  [];
moviefile = [];
thresh = [];
ROIs= [];
w=[];
h= [];
ff = [];
nframes=[];
frame= [];
posx = [];
posy = [];
orientation = [];
flymissing = [];
heading = [];
allflies= [];
area=[];
mask = [];
rp = [];
displayfigure= [];
fps = [];
movie = [];
t=[];
collision = [];
adjacency = []; % adjancency is like collision, but indicates that the k-means algo. was used to seperate flies. 
WingExtention = [];


CopulationTimes = [];
Copulation = [];
WingExtention = [];
if nargin < 2
    StartFromHere = [];
end



%% choose files to track
source = cd;
allfiles = uigetfile('*.mat','MultiSelect','on'); % makes sure only annotated files are chosen
if ~ischar(allfiles)
% convert this into a useful format
thesefiles = [];
for fi = 1:length(allfiles)
    thesefiles = [thesefiles dir(strcat(source,oss,cell2mat(allfiles(fi))))];
end
else
    thesefiles(1).name = allfiles;
end

for fi = 1:length(thesefiles)
    % clear all variables
    n = [];
    narenas=  [];
    moviefile = [];
    thresh = [];
    ROIs= [];
    w=[];
    h= [];
    ff = [];
    nframes=[];
    frame= [];
    posx = [];
    posy = [];
    orientation = [];
    flymissing = [];
    heading = [];
    allflies= [];
    area=[];
    mask = [];
    rp = [];
    displayfigure= [];
    fps = [];
    movie = [];
    t=[];
    collision = [];
    adjacency = []; % adjancency is like collision, but indicates that the k-means algo. was used to seperate flies. 
    WingExtention = [];
    StartTracking =[];
    
    
    disp('Loading new file....')
    disp(thesefiles(fi).name)
    load(thesefiles(fi).name)
    
    % check if this file is fully analysed


    if ~isempty(posx)
        if ~any(isnan(posx(:,StopTracking-1)))
            % fully analysed
            if nargin == 1
                disp('This file looks fully analysed. I will skip this...')
            else
                if StartFromHere == 0
                    disp('Trashing all old data and re-starting...')
                    StartFromHere = StartTracking;
                    TrackCore2;
                else
                    disp('Starting from specified location...')
                    TrackCore2;
                end
                
            end
        else
            % not fully analysed. maybe partially anlysed?
            % start from where you stopped before
            if StartFromHere == 0
                StartFromHere = StartTracking;
                disp('Trashing all old data and re-starting...')
            end
            TrackCore2;
        end
    else
        % new file.
        TrackCore2;
    end
    
    
   
    close(displayfigure)
    disp('All done with this file!')
end




%% subfunctions
    function [] = TrackCore2()
        % core algo
        InitialiseTracking;
        
        CheckThresh;
        
        t = tic;
        for frame = StartFromHere:StopTracking  
            
            
            PrepImage;
            
            DetectObjects(0);
            
            rp=DiscardSmallObjects(rp);
 
            
            % is everything OK?
            if length(rp) == n
                % all OK
            elseif length(rp) < n
                % either collision or fly missing. which is it?
                % did two flies come rather close last frame?
                temp = [posx(:,frame-1) posy(:,frame-1)];

                if min(pdist(temp)) < 50
                    % some two flies closer than 50px in previous frame
                    % mark them as colliding
                    d = squareform(pdist(temp));
                    d(d==0) = Inf;
                    d = d<50;
                    collision(logical(sum(d)),frame) = 1;
                else
                    % flies did not come close, assuming fly missing.
                end
            else
                % discard objects didn't work. that's OK. Assign objects
                % will work gracefully.
            end

            
      
           AssignObjects2; 
            
           DetectWingExtention;
           
           CleanWingExtention;
            
           UpdateDisplay;
            

            % save every 1000 frames of data
            if  ~(ceil(frame/1000)-(frame/1000))
                disp('Saving...')
                save(thesefiles(fi).name,'posx','posy','orientation','adjacency','heading','flymissing','collision','area','WingExtention','-append')
        
            end
        end
        % save all data
        save(thesefiles(fi).name,'posx','posy','orientation','adjacency','heading','flymissing','collision','area','WingExtention','-append')
        
    end



    function []  = CleanWingExtention()
        % if there are two flies in the same arena with wings extended,
        % resolve them:
        for ni=1:narenas
            otherfly = ni*2;
            thisfly = ni*2-1;
            if sum(WingExtention(thisfly:otherfly,frame)) == 2
                % in the previous frame, did only one of them have the wing
                % extended?
                if sum(WingExtention(thisfly:otherfly,frame-1)) == 1
                    % only one had we in previous frame
                    if WingExtention(thisfly,frame-1) 
                        WingExtention(otherfly,frame)=0;
                    else
                        WingExtention(thisfly,frame)=0;
                    end
                elseif sum(WingExtention(thisfly:otherfly,frame==1)) == 0
                    % neither had we in previous frame
                    % so we remove both
                    WingExtention(thisfly:otherfly,frame)=0;
                end
                
            end
            
        end
    end

    function [] = InitialiseTracking()
        disp('Initialising tracking....')
        % get movie parameters and initlaise movie reader
        movie = VideoReader(moviefile)
        % grab params and make placeholders
        h =  get(movie,'Height');
        w=get(movie,'Width');
        nframes = get(movie,'NumberOfFrames');
        
        % check if there is already some data here
        if ~isempty(posx) && any(~isnan(posx(1,:)))
            % this has already been at least partially analysed.
            disp('Looks like this file has already been analysed.')
            % do we want to start tracking from somewhere particular?
            if ~isempty(StartFromHere)
                disp('OK. Starting from custom location...')
                
            else
                % start from where you stopped
                StartFromHere = find(~isnan(posx(1,:)),1,'last') - 1;
            end
            % wipe all info from StartFromHere onwards
            posx(:,StartFromHere:end) = NaN;
            posy(:,StartFromHere:end) = NaN;
            orientation(:,StartFromHere:end) = NaN;
            collision(:,StartFromHere:end) = 0;
            adjacency(:,StartFromHere:end) = 0;
            flymissing(:,StartFromHere:end) = 0;
            WingExtention(:,StartFromHere:end) = 0;
            heading(:,StartFromHere:end) = 0;
            allflies= 1:n;
        else
            % nope. raw file.
            disp('Looks like this is a new video file. Will begin tracking from beginning...')
            flymissing = zeros(n,nframes);
            collision =  flymissing;
            adjacency = flymissing;
            allflies= 1:n;
            posx = NaN(n,nframes);
            posy = posx;
            orientation = posx;
            area = posx;
            WingExtention = collision;
            heading = zeros(n,nframes);
            StartFromHere = StartTracking;
        end
        
        
        % build logical array of ROIs
        disp('Building ROI mask...')
        
        ff = read(movie,StartTracking);
        mask = squeeze(0*ff(:,:,1));
        for i = 1:w
            for j =1:h
                maskthis = 0;
                for k = 1:narenas
                    maskthis = maskthis + ((i-ROIs(1,k))^2 + (j-ROIs(2,k))^2 < ROIs(3,k)^2);
                end
                mask(j,i) = maskthis;
            end
        end
        disp('DONE')
        
        if v
            % create a display
            displayfigure=figure; hold on
             imagesc(ff), hold on
        end

    end

    function  [] = CheckThresh()
        % automatically find thresh.
        frame = StartTracking;
        PrepImage;
        thresh = graythresh(ff);
        
        
    end

    function [] = PrepImage()
        ff = read(movie,frame);
        ff = (255-ff(:,:,1));
        ff =  imtophat(ff,strel('disk',20)); % remove background
        ff = ff.*mask; % mask it
    end

    function  [] = DetectObjects(bb)
        if bb
            rp =[];
            l = logical(im2bw(ff,thresh));
            rp = regionprops(l,'Orientation','Centroid','Area','PixelList','BoundingBox');
        else
            rp =[];
            l = logical(im2bw(ff,thresh));
            rp = regionprops(l,'Orientation','Centroid','Area','PixelList');
        end
    end

    function [regions] = DiscardSmallObjects(regions)
        % throw out small objects
        badregion = [regions.Area] < min_area;
        regions(badregion) = [];
    end

    function [] = SplitBigObjects()
        DetectObjects(1);
        rp=DiscardSmallObjects(rp);
        startn = length(rp);
        
        mashedupobjects = [];
        for i = 1:length(rp)
            if rp(i).Area > max_area
                % only those objects that are close to putatively colloding flies
                % will be looked at.
                temp = rp(i).Centroid;
                d = pdist2([posx(logical(collision(:,frame)),frame-1),posy(logical(collision(:,frame)),frame-1)],temp);
                if min(d) < 30
                    mashedupobjects = [mashedupobjects i];
                end
            end
        end

        unmashedflies = []; % this contains a regionprops struct array with (newly) unmashed flies. 
        formerlymashedflies= [];
        if any(mashedupobjects)
            % try to separate them by increasing threshold
            for i = mashedupobjects
                bb = round(rp(i).BoundingBox);
                megafly= ff(bb(2)+1:bb(2)+bb(4),bb(1)+1:bb(1)+bb(3));
                % open up the image
                megafly= imopen(megafly,strel('disk',2));
                newthresh = graythresh(megafly)-0.05;
                split=1;
                while split < 2 && newthresh < 0.95
                    newthresh = newthresh+0.01;
                    splitflies=regionprops(im2bw(megafly,newthresh),'Orientation','PixelList','Centroid','Area','BoundingBox');
                    splitflies = DiscardSmallObjects(splitflies);                    
                    split = length(splitflies);
                    % fix centroids
                    for j = 1:split
                        splitflies(j).Centroid(1) = splitflies(j).Centroid(1) + bb(1);
                        splitflies(j).Centroid(2) = splitflies(j).Centroid(2) + bb(2);
                    end
                end
                if split > 1 % succesful split
                    unmashedflies = [unmashedflies; splitflies];  
                    formerlymashedflies = [ formerlymashedflies i];
                end


                
            end
            % now delete the mashed up flies
            rp(formerlymashedflies) = [];
            % and add the unmashed flies
            if ~isempty(unmashedflies)
                try
                    rp = [rp;unmashedflies];
                catch
                    keyboard
                end
            end
            
            % check that the number of regions has not decreSED
            if length(rp) < startn
                keyboard
            end
        else
            % no mashed up flies
        end
    end


    function [] = AssignObjects2()
        % this has two different cases: when there are more objects than
        % flies, it goes through each fly and assigns the nearest object.
        % if not, it goes through each object and assigns it to the nearest
        % fly
        if frame == StartTracking
            % special case
            for i = 1:n
                posx(i,StartTracking) = rp(i).Centroid(1);
                posy(i,StartTracking) = rp(i).Centroid(2);
                orientation(i,StartTracking) = -rp(i).Orientation;
                area(i,StartTracking) = rp(i).Area;
                
               
            end
        else
            if length(rp) < n
             
                % assign objects to flies
                for j = 1:length(rp)
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
                        keyboard
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
            
                    elseif isinf(step)
                        % fly is jumping, probably
                        
                        % keyboard
                    elseif step > jump
                        if flymissing(thisfly,frame-1) 
                            % fly was missing last frame, so it's OK
                            posx(thisfly,frame) = rp(j).Centroid(1);
                            posy(thisfly,frame) = rp(j).Centroid(2);
                            area(thisfly,frame) = rp(j).Area;
             
                            orientation(thisfly,frame) = -rp(j).Orientation;
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
            else % at least as many objects as flies
                % assingn flies to objects
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
                        return
                    end
                    [step,thisobj] = min(d);
                    if step < jump
                        % assign this object to this fly
                        posx(i,frame) = rp(thisobj).Centroid(1);
                        posy(i,frame) = rp(thisobj).Centroid(2);
                        area(i,frame) = rp(thisobj).Area;
                        orientation(i,frame) = -rp(thisobj).Orientation;
                        % mark it as assigned
                        rp(thisobj).Centroid = [Inf Inf];
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
                            % mark it as assigned
                            rp(thisobj).Centroid = [Inf Inf];
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
                % build a headings matrix
                if frame - StartTracking > 6
                    hh = [posx(i,frame)-posx(i,frame-5) posy(i,frame)-posy(i,frame-5)];                   
                else
                     hh = [posx(i,frame)-posx(i,frame-1) posy(i,frame)-posy(i,frame-1)];
                end
                if hh(1) < 0
                    heading(i,frame)=180+atand(hh(2)/hh(1));
                else
                    heading(i,frame)=atand(hh(2)/hh(1));
                end
                if heading(i,frame) < 0
                    heading(i,frame) = 360+heading(i,frame);

                end

                % attempt to fix orientations
                min_step=10;
                % is the heading closer to the orientation or to
                % 90+orientation?

                if orientation(i,frame) < 0
                    orientation(i,frame) = 360+orientation(i,frame);

                end



                flipo = mod(orientation(i,frame)+180,360);
                step = sqrt((posx(i,frame)-posx(i,frame-1)).^2 +(posy(i,frame)-posy(i,frame-1)).^2);
                if  (abs(heading(i,frame)-orientation(i,frame)) > abs(heading(i,frame) - flipo)) && step>min_step
                    orientation(i,frame) = 180+orientation(i,frame);
                elseif step<min_step && AngularDifference(orientation(i,frame),orientation(i,frame-1)) > 120
                    % using old orientation not a good idea, just used the
                    % flipped one
                    % orientation(i,frame) = orientation(i,frame-1);
                    orientation(i,frame) = 180+orientation(i,frame);
                end


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
                if min(nonzeros(temp)) < 40
                    collision(i,frame) = 1;

                end 
            end
                
        end
        
        % now we have another check that looks for flies that suddenly
        % double in area from the last frame. 
        for i = 1:n
            if area(i,frame)/area(i,frame-1) > 1.5 % 50% increase in 1 frame
                % suspicious
                switch mod(i,2)
                    case 1
                        otherfly=i+1;
                    case 0
                        otherfly=i-1;
                end
                % are these flies in a collision?
                if (collision(i,frame)*collision(otherfly,frame)) && length(rp)<4%#ok<BDLOG>
                    % so this has been counted as a collision
                    % find the region that was assigned to this and attempt
                    % to split it
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
                    d = d(1,2:end);
                    [~,thisobj] = min(d);
                    
                    [rp2, SuccessfulSplit] = SeperateCollidingFlies(rp,thisobj);
                    if SuccessfulSplit == 1
                        % assign newly identified objects to this fly and
                        % otherfly
                        rp2=ForceAssignObjects2Flies(rp2,i,otherfly);
                        % unmark the collision
                        collision(i,frame) = 0;
                        collision(otherfly,frame) = 0;
                        % unmark the missing fly
                        flymissing(i,frame)=0;
                        flymissing(otherfly,frame) = 0;
                        % m,erge objects
                        rp(thisobj) = [];

                        rp = [rp; rp2];
                    elseif SuccessfulSplit == 0
                        % split failure. give up.
                        if any(abs(pdist2([rp(thisobj).Centroid],ROIs([1 2],:)')-mean(ROIs(3,:)))<35)
                            % flies are colliding really close to the edge.
                            % mark both flies are colliding, and missing,
                            % and do not attempt to assign anything.
                            flymissing(i,frame)=1;
                            flymissing(i,otherfly)= 1;
                            posx(i,frame) = posx(i,frame-1); posy(i,frame) = posy(i,frame-1);
                            posx(otherfly,frame) = posx(otherfly,frame-1); posy(otherfly,frame) = posy(otherfly,frame-1);
                            collision(i,frame) = 1;
                            collision(otherfly,frame) = 1;
                        end
                    elseif SuccessfulSplit == 2
                        % adjacnect flies
                        % assign newly identified objects to this fly and
                        % otherfly
                        rp2=ForceAssignObjects2Flies(rp2,i,otherfly);
                        % MARK the collision
                        collision(i,frame) = 1;
                        collision(otherfly,frame) = 1;
                        adjacency(i,frame)=1;
                        adjacency(otherfly,frame)=1;
                        % unmark the missing fly
                        flymissing(i,frame)=0;
                        flymissing(otherfly,frame) = 0;
                        % merge objects
                        rp(thisobj) = [];
                        if length(rp2) == 2
                          rp =[rp; reshape(rp2,2,1)];
                        end


                    end

                end
            end
        end
        
        
        
    end

    function [thisobj] = FindClosestObject2Fly(rp,thisfly)
        % finds the closest object among a list of regions to a fly
        o_centroids = [];
        for j = 1:length(rp)
            o_centroids=[o_centroids; rp(j).Centroid]; % rearranging all object centroids into a matrix
        end
        temp = [posx(thisfly,frame-1) posy(thisfly,frame-1); o_centroids];

        % figure out if fly is on left or right arena
        if posx(thisfly,frame-1) < DividingLine
            % on left
            temp(temp(:,1) > DividingLine,:) = Inf;
        else
            temp(temp(:,1) < DividingLine,:) = Inf;
        end

        % find closest object to ith fly
        d = squareform(pdist(temp));
        d = d(1,2:end);
        [~,thisobj] = min(d);
    end

    function [rp2] = ForceAssignObjects2Flies(rp2,thisfly,otherfly)
        % what is says on the tin. called only in special cases.
        % explicitly assumes that there are 2 flies and 2 objects
        
        % assign i
        [thisobj] = FindClosestObject2Fly(rp2,thisfly);
        posx(thisfly,frame) = rp2(thisobj).Centroid(1);
        posy(thisfly,frame) = rp2(thisobj).Centroid(2);
        area(thisfly,frame) = sum([rp2.Area])/2; % areas can't be trusted
            orientation(thisfly,frame) = -rp2(thisobj).Orientation;

        % mark it as assigned
        rp2(thisobj).Centroid = [Inf Inf];
        
        % assign otherfly
        thisfly=otherfly;
        [thisobj] = FindClosestObject2Fly(rp2,thisfly);
        posx(thisfly,frame) = rp2(thisobj).Centroid(1);
        posy(thisfly,frame) = rp2(thisobj).Centroid(2);
        area(thisfly,frame) = sum([rp2.Area])/2; % areas can't be trusted
        orientation(thisfly,frame) = -rp2(thisobj).Orientation;
        % mark it as assigned
        rp2(thisobj).Centroid = [Inf Inf];
        
        
        
        % change the areas
        rp2(1).Area = area(thisfly,frame);
        rp2(2).Area = area(thisfly,frame);
        
    end

    function [rp2,SuccessfulSplit] = SeperateCollidingFlies(rp,thisobj)
        cx = round(rp(thisobj).Centroid(1));
        cy = round(rp(thisobj).Centroid(2));
        % make sure we are cutting it nicely
        thisfly = CutImage(ff,[cy cx],75);
        disc_sizes = [1:2:6 7 8 9];
        SuccessfulSplit=0;
        rp2=[];
        for k = disc_sizes
            % open the image using a disc
            if ~SuccessfulSplit
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
                            SuccessfulSplit = 1;
                        end
                    end
                end
            end
            
            
        end
        if SuccessfulSplit ==0 
            % disp('Split failure...trying k-means seperation...')
            % try to seperate them using k-means
            k=5;
            thisfly= (logical(im2bw(imopen(thisfly,strel('disk',k)),thresh)));
            [xk,yk]=ind2sub([151,151],find(thisfly));
            [~,rp2centroid]=kmeans([xk yk],2);
            
            % reconstruct a fake regionprops struct
            rp2(1).Area = rp(thisobj).Area/2;
            rp2(2).Area = rp(thisobj).Area/2;
            rp2(1).Centroid(1) = rp2centroid(1,2) + cx - 75;
            rp2(1).Centroid(2) = rp2centroid(1,1) + cy - 75;
            rp2(2).Centroid(1) = rp2centroid(2,2) + cx - 75;
            rp2(2).Centroid(2) = rp2centroid(2,1) + cy - 75;
            
            
            
            SuccessfulSplit = 2;
            
            % inherit orientation.
            rp2(1).Orientation = rp(thisobj).Orientation;
            rp2(2).Orientation = rp(thisobj).Orientation;
            
        end
        
        
        
        
    end 

    function [] = DetectWingExtention()
        % this function detects Wing Extension events. 
        % this is how the alogirthm works:
        % 
        % the following conditions have to be met:
        % 1. is the fly visible?
        % 2. is is the other fly visible?
        % 3. are they sufficently close? (define a distance)
        % 4. are the fly's wing extension regions clear of the edge? 
        % 5. are the fly's wing extension regions clear fo the other fly?

        % if all these conditions are met, 

        % - extract the fly image. 
        % - threshold the image, only pixels above 1/2 the brightest pixels
        % - find the orientation of the fly
        % - rotate the fly to orient it vertically 
        % - remove the legs by eroding the image with a 2 disc
        % - remove the body by removing all bright pixels
        % - compare pixel intensities of the right to the left. 

        for i = 1:n
            % set rejectthis variable.
            rejectthis = 1; % automatically assume that we won't look at this fly
            rejectreason=0;
            if ~flymissing(i,frame)  % ------------------------------- step 1 passed
                cx = round(posx(i,frame));
                cy = round(posy(i,frame));
                % are both flies visible?
                switch mod(i,2)
                    case 1
                        otherfly=i+1;
                    case 0
                        otherfly=i-1;
                end
                if flymissing(otherfly,frame)
                    % reject
                    rejectreason = 1;
                else % ------------------------------------------------ step 2 passed
                    % are the two flies very far apart?
                    if  pdist2([posx(i,frame),posy(i,frame)],[posx(otherfly,frame),posy(otherfly,frame)])>200
                        % reject
                        rejectreason = 2;
                    else % ------------------------------------------------ step 3 passed
                        % extract fly
                        try
                            
                            thisfly = CutImage(ff,[cy cx],50);
                        catch
                            keyboard
                        end
                        % find points orthogonal to body axis,around 27 pixels off
                        [left,right,leftw,rightw] = ExtractWingPixelValues(thisfly,orientation(i,frame));
                        left(1) = posx(i,frame)+left(1)-50;
                        left(2) = posy(i,frame)+left(2)-50;
                        right(1) = posx(i,frame)+right(1)-50;
                        right(2) = posy(i,frame)+right(2)-50;
                        % are flies wing locations clear of edge
                        temp= abs(pdist2([left;right],ROIs([1 2],:)')-mean(ROIs(3,:))); % radial distances to circle edge

                        if max(max(temp))<15
                            % fail. reject.
                             rejectreason = 3;
                        else
                            % ------------------------------------------------ step 4 passed
                            % are flies wing locations clear of other fly?
                            temp=pdist2([left;right],[posx(:,frame),posy(:,frame)]);
                            temp(temp<26) = []; % remove reference to this fly
                            if any(temp<30)
                                % fail. reject.
                                rejectreason = 4;
                            else
                                % ------------------------------------------------ step 5 passed
                                % all OK!
                                rejectthis = 0;
                            end
                        end 

                    end
                    
                end
                
                
                % remove other fly
                thisfly = ff;
                otherflyregion=find(area(otherfly,frame)==[rp.Area]);
                if isempty(otherflyregion)
                        % cant find other fly propeorly
                        rejectreason=9;
                        rejectthis=1;
                elseif length(otherflyregion) > 1
                    % probably colliding flies, that have been seoerated
                    % forecefully by k-means
                    % try to find the other fly anyway
                    if any((orientation(otherfly,frame) - [rp.Orientation]) == 0)
                        otherflyregion = find((orientation(otherfly,frame) - [rp.Orientation]) == 0);
                    elseif any((orientation(otherfly,frame) + [rp.Orientation]) == 0)
                        otherflyregion = find((orientation(otherfly,frame) + [rp.Orientation]) == 0);
                    end
                    if length(otherflyregion) > 1 
                        rejectthis = 1;
                        rejecttreason = 13;
                    end
                    
                end
                
                % findally, see if fly was missing in the past
                if any(flymissing(i,frame-5:frame))
                    rejectthis = 1;
                    rejectreason  =11;
                end
                

                
                if ~rejectthis
                    % we will consider this for wing extention

                     thisfly(rp(otherflyregion).PixelList(:,2),rp(otherflyregion).PixelList(:,1))=0;



                    thisfly = CutImage(thisfly,[cy cx],50);
                    thisfly=imerode(thisfly,strel('disk',2)); % remove legs
                    % find orientation of fly
                    thisfly2 = thisfly>max(max(thisfly))/2;
                    r = regionprops(thisfly2,'Orientation','Centroid','Area');
                    r([r.Area]<max([r.Area])/4) = []; % remove small objects
                    [~,flybod]=min(sum(abs(vertcat(r.Centroid)-50)'));
                    % rotate fly so that is oriented vertically
                        thisfly=imrotate(thisfly,90-(r(flybod).Orientation),'crop');

                    % remove fly body
                    thisfly(thisfly>max(max(thisfly))/2) = 0;
                    % remove background noise
                    thisfly(thisfly<11) = 0;
                    % remove remants of the body
                    thisfly = imerode(thisfly,strel('disk',2));
                    
                    % just remove all the middle
                     thisfly(:,40:60) = 0;
                    
                    % find the wing
                    r = regionprops(thisfly>5,thisfly,'Centroid','Area','MeanIntensity');
                    r([r.Area]<60) = []; % remove small objects 
                    if ~isempty(r)
                        if length(r) == 1
                            if (abs(r.Centroid(1)-50) > 15) && (abs(r.Centroid(1)-50) < 40) && abs(r.Centroid(2)-50) < 10 && r.MeanIntensity > 15
                                % far away from midline horizontally, but
                                % close to midline vertically.
                                WingExtention(i,frame) = 1;  


                            end
                        else
                            % reject.
                        end

                    end
                end
                
            end            
        end 

    end

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
    end

    function  []  = UpdateDisplay()
        if v
            figure(displayfigure);
            cla
            imagesc(ff), hold on
            che = 0;
            for i = 1:n
                if flymissing(i,frame)
                    scatter(posx(i,frame),posy(i,frame),'r','filled')
                    che = che+1;
                else
                    triangle([posx(i,frame) posy(i,frame)],orientation(i,frame),10,'k');
                    triangle([posx(i,frame) posy(i,frame)],heading(i,frame),10,'b');
                    che = che+1;
                end

            end
            if che~=n
                keyboard
            end
           
            
            tt=toc(t);
            fps = oval((frame-StartFromHere)/tt,3);
            cf = [];
            if any(WingExtention(:,frame))
                scatter(posx(find(WingExtention(:,frame)),frame),posy(find(WingExtention(:,frame)),frame),1500,'g')
                scatter(posx(find(WingExtention(:,frame)),frame),posy(find(WingExtention(:,frame)),frame),1600,'g')
            else
                if any(collision(:,frame))
                    cf = mat2str(find(collision(:,frame)));
                    title(strkat('Frame ', mat2str(frame),' at ', fps , 'fps. Colliding flies:',cf));
                else
                    title(strkat('Frame ', mat2str(frame),' at ', fps , 'fps.'));
                end
            end
            
        
        else
            if rand > 0.95
                tt=toc(t);
                fps = oval((frame-StartFromHere)/tt,3);
                fprintf(strkat('\n Frame # ', mat2str(frame), '   @ ', fps, 'fps'));
            end
        end
        

        
    end

        


end