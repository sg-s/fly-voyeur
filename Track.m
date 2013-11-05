% return trajectories
% Track.m
% this is the actual engine of the tracking code
% this uses some metadata manually entereed about each movie file to
% process movies. this is meant to be run in the background, or when user
% attention is not required. 
% created by Srinivas Gorur-Shandilya at 19:56 , 29 August 2013. Contact me
% at http://srinivas.gs/contact/
function [] = Track(v)
%% global params
    min_area = 300;
    jump = 100;
    max_area = 1000;
    
% initialise variables
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

%% choose files to track
allfiles = uigetfile('*.mat','MultiSelect','on'); % makes sure only annotated files are chosen
if ~ischar(allfiles)
% convert this into a useful format
thesefiles = [];
for fi = 1:length(allfiles)
    thesefiles = [thesefiles dir(strcat(source,cell2mat(allfiles(fi))))];
end
else
    thesefiles(1).name = allfiles;
end

for fi = 1:length(thesefiles)
    load(thesefiles(fi).name)
    TrackCore;
    
end

    function [] = TrackCore()
    %% get movie parameters and initlaise movie reader

    movie = VideoReader(moviefile);
    h =  get(movie,'Height');
    w=get(movie,'Width');
    nframes = get(movie,'NumberOfFrames');

    flymissing = zeros(n,nframes);
    allflies= 1:n;
    lazy_fly = 1; % minimum distance it must move for orientation to be recomputed

    %% initialise variables
    posx = NaN(n,nframes);
    posy = posx;
    orientation = posx;
    area = posx;


    %% build logical array of ROIs
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
    % throw out everyhting outside ROIs
    ff = 255-ff(:,:,1);
    ff = ff.*mask;
    
    %% detect objects on first frame
     
    l = logical(im2bw(ff,thresh));
    rp = regionprops(l,'Orientation','Centroid','Area','BoundingBox');
    if length(rp) > n % number of flies
        % throw out small objects
        % throw out small objects
        badregion = zeros(1,length(rp));
        for j = 1:length(rp)
            if rp(j).Area < min_area
                badregion(j) = 1;
            end
        end
        rp(logical(badregion)) = [];
        % check
        if length(rp) > n
            keyboard
        end
    elseif length(rp) < n
        keyboard
    end
    if length(rp) ~= n
        frame = StartTracking;
        % check if there are mashed up flies
        mashedupflies = [];
        for i = 1:length(rp)
            if rp(i).Area > max_area
                mashedupflies = [mashedupflies i];
            end
        end
        unmashedflies = [];
        if any(mashedupflies)
            % try to separate them by increasing threshold
            for i = mashedupflies
                bb = round(rp(i).BoundingBox);
                megafly= ff(bb(2)+1:bb(2)+bb(4),bb(1)+1:bb(1)+bb(3));
                newthresh = graythresh(megafly)-0.05;
                split=1;
                while split == 1
                    newthresh = newthresh+0.05;
                    splitflies=regionprops(im2bw(megafly,newthresh),'Orientation','Centroid','Area','BoundingBox');
                    badregion = zeros(1,length(splitflies));
                    % remove junk
                    for j = 1:length(splitflies)
                        % fix the centroids
                        splitflies(j).Centroid(1) = splitflies(j).Centroid(1) + bb(1);
                        splitflies(j).Centroid(2) = splitflies(j).Centroid(2) + bb(2);
                        if splitflies(j).Area < min_area
                            badregion(j) = 1;
                        end
                    end
                    
                    splitflies(logical(badregion)) = [];
                    split = length(splitflies);

                end
                unmashedflies = [unmashedflies splitflies];
                
            end
            % now delete the mashed up flies
            rp(mashedupflies) = [];
            % and add the unmashed flies
            rp = [rp;unmashedflies];
        else
            keyboard
        end
        
        
        for i = 1:n
            posx(i,StartTracking) = rp(i).Centroid(1);
            posy(i,StartTracking) = rp(i).Centroid(2);
            orientation(i,StartTracking) = -rp(i).Orientation;
            area(i,StartTracking) = rp(i).Area;
        end
%         % ask user to specify positions of flies
%         figure, hold on
%         imagesc(ff), title('Mark all flies by clicking on each once')
%         [posx(:,StartTracking),posy(:,StartTracking)] = ginput(n);
        
    else
        for i = 1:n
            posx(i,StartTracking) = rp(i).Centroid(1);
            posy(i,StartTracking) = rp(i).Centroid(2);
            orientation(i,StartTracking) = -rp(i).Orientation;
            area(i,StartTracking) = rp(i).Area;
        end
        
    end
    
    
    


    %% track
    if v
        df=figure; hold on, imagesc(ff)
        axis image
    end
    t=tic;
    for frame = StartTracking+1:1:StopTracking
        %% speed
        tt=toc(t);
        fps = oval((frame-StartTracking)/tt,3);
        
        % load the current frame
        ff = read(movie,frame);
        % throw out everyhting outside ROIs
        ff = 255-ff(:,:,1);
       ff = ff.*mask;

        % thresh and find objects
        l = logical(im2bw(ff,thresh));
        rp = regionprops(l,'Orientation','Centroid','Area','Perimeter','MajorAxisLength','Orientation','BoundingBox');

        % throw out small objects
        badregion = zeros(1,length(rp));
        for j = 1:length(rp)
            if rp(j).Area < min_area
                badregion(j) = 1;
            end
        end
        rp(logical(badregion)) = [];
        
        % check for mashed up objects
      mashedupflies = [];
        for i = 1:length(rp)
            if rp(i).Area > max_area
                mashedupflies = [mashedupflies i];
            end
        end
        unmashedflies = [];
        if any(mashedupflies)
            % try to separate them by increasing threshold
            for i = mashedupflies
                bb = round(rp(i).BoundingBox);
                megafly= ff(bb(2)+1:bb(2)+bb(4),bb(1)+1:bb(1)+bb(3));
                newthresh = graythresh(megafly)-0.05;
                split=1;
                while split == 1
                    newthresh = newthresh+0.05;
                    splitflies=regionprops(im2bw(megafly,newthresh),'Orientation','Centroid','Area','Perimeter','MajorAxisLength','Orientation','BoundingBox');
                    badregion = zeros(1,length(splitflies));
                    % remove junk
                    for j = 1:length(splitflies)
                        % fix the centroids
                        splitflies(j).Centroid(1) = splitflies(j).Centroid(1) + bb(1);
                        splitflies(j).Centroid(2) = splitflies(j).Centroid(2) + bb(2);
                        if splitflies(j).Area < min_area
                            badregion(j) = 1;
                        end
                    end
                    
                    splitflies(logical(badregion)) = [];
                    split = length(splitflies);

                end
                unmashedflies = [unmashedflies; splitflies];
                
            end
            % now delete the mashed up flies
            rp(mashedupflies) = [];
            % and add the unmashed flies
            try
                rp = [rp;unmashedflies];
            catch
                keyboard
            end
        else
            % no mashed up flies
        end
        
        

        % for each fly, find the nearest unassigned object and assign it to
        % the fly
        for i = [allflies(flymissing(:,frame-1)==0) allflies(flymissing(:,frame-1)==1)]  % this prioritises OK flies
            o_centroids = [];
            for j = 1:length(rp)
                o_centroids=[o_centroids; rp(j).Centroid];
            end
            temp = [posx(i,frame-1) posy(i,frame-1); o_centroids];

            % figure out if fly is on left or right arena
            if posx(i,frame-1) < DividingLine
                % on left
                temp(temp(:,1) > DividingLine,:) = Inf;
            else
                temp(temp(:,1) < DividingLine,:) = Inf;
            end


            d = squareform(pdist(temp));
            d = d(1,2:end);
            [step,thisobj] = min(d);
            if step < jump
                % assign this object to this fly
                posx(i,frame) = rp(thisobj).Centroid(1);
                posy(i,frame) = rp(thisobj).Centroid(2);
                area(i,frame) = rp(thisobj).Area;
                perimeter(i,frame) = rp(thisobj).Perimeter;
                orientation(i,frame) = -rp(thisobj).Orientation;
                % mark it as assigned
                rp(thisobj).Centroid = [Inf Inf];
            elseif isinf(step)
                % if this is a missing fly, keep going
                % this means the fly has just gone missing, and other
                % flies elsewhere in other arenas are segmented
                posx(i,frame) = posx(i,frame-1);
                posy(i,frame) = posy(i,frame-1);
                perimeter(i,frame) = 0;
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
                    perimeter(i,frame) = rp(thisobj).Perimeter;
                    orientation(i,frame) = -rp(thisobj).Orientation;
                    % mark it as assigned
                    rp(thisobj).Centroid = [Inf Inf];
                else
                    % fly goes missing now
                    posx(i,frame) = posx(i,frame-1);
                    posy(i,frame) = posy(i,frame-1);
                    area(i,frame) = 0;
                    perimeter(i,frame) = 0;
                    flymissing(i,frame) = 1;

                end

            end
            
            % now fix the orienations
            d = 0.8*rp(thisobj).MajorAxisLength/2;
            theta = rp(thisobj).Orientation;
            e1 = round([posx(i,frame) + d*cosd(theta) posy(i,frame) + d*sind(theta)]);
            e2 = round([posx(i,frame) - d*cosd(theta) posy(i,frame) - d*sind(theta)]);
%             axis image, hold on
%             scatter(e1(1),e1(2))
%             scatter(e2(1),e2(2))
            % grab points around this
            bs = 2; % box size
            terminal(1) = mean(mean(ff(e1(2)-bs:e1(2)+bs,e1(1)-bs:e1(1)+bs)));
            terminal(2) = mean(mean(ff(e2(2)-bs:e2(2)+bs,e2(1)-bs:e2(1)+bs)));
            if terminal(1) < terminal(2)
                orientation(i,frame) = 180+orientation(i,frame);
            end

            
        end


       
        



        % error catchers
        if any(diff(sort(posx(:,frame)))==0)
            keyboard
        end
        if sum(flymissing(:,frame))
            keyboard
        end
        

        


        % fix orientations
%         for i = 1:n
%             if ~flymissing(i,frame)
%                 % the following snippet calcualtes orientation based on
%                 % heading
%                 % caluclate heading
%                 hy = (posy(i,frame) - posy(i,frame-1));
%                 hx = (posx(i,frame) - posx(i,frame-1));
%                 if cosd(orientation(i,frame))*hx > 0 && sind(orientation(i,frame))*hy
%                 else
%                     orientation(i,frame) = 180+orientation(i,frame);
%                 end
% 
%                 % add some inertia to heading change
%                 if hx+hy < lazy_fly
%                     orientation(i,frame) = orientation(i,frame-1);
%                 end
% 
%             end
%         end

        
        % plot
        if v
            figure(df);
            cla
            imagesc(ff), hold on
            for i = 1:n
                if flymissing(i,frame)
                    scatter(posx(i,frame),posy(i,frame),'r','filled')
                else
                    triangle([posx(i,frame) posy(i,frame)],orientation(i,frame),10,'k');
                end

            end
            title(strkat('Frame ', mat2str(frame),' at ', fps , 'fps'));
        
        else
            if rand > 0.9
                fprintf(strkat('\n Frame # ', mat2str(frame), '   @ ', fps, 'fps'));
            end
        end
        
   



    end

    end

end % end of function
