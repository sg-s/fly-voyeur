% return trajectories
% Track3Patch.m
% Track3Patch is a special instance of Track3 that redoes the analysis on
% video files, but only on frames where a fly is missing. this is to fix
% the mess caused by a rogue bug in a previous interation of Track3. 
% this is the actual engine of the tracking code
% this uses some metadata manually entereed about each movie file to
% process movies. this is meant to be run in the background, or when user
% attention is not required. 
% created by Srinivas Gorur-Shandilya at 19:56 , 29 August 2013. Contact me
% at http://srinivas.gs/contact/
% Track3 is a large re-write of Track2 where all the subfunctions have been
% split up into smaller files for better sanity of debugging.
function [] = Track3(v,ForceStartFromHere)
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
    % create all variables
    % movie parameters
    n = []; % number of flies
    narenas=  []; % number of arenas
    moviefile = [];
    ROIs= [];
    thresh = [];
    w=[];
    h= [];
    nframes=[];
    ff = [];
    allflies= [];
    mask = [];
    movie = [];
    t=[];
    StartTracking =[];
    StopTracking=[];
    DividingLine = [];
    LeftStart = [];
    RightStart =[];
    
    % core tracking parameters
    min_area = 400;
    
    % temporary variables
    frame= [];
    rp = [];
    
    % data output
    posx = [];
    posy = [];
    orientation = [];
    flymissing = [];
    heading = [];
    area=[];
    collision = [];
    adjacency = []; % adjancency is like collision, but indicates that the k-means algo. was used to seperate flies. 
    WingExtention = [];
   
    % housekeeping
    displayfigure= [];
    fps = [];
    

    disp('Loading new file....')
    disp(thesefiles(fi).name)
    warning off
    load(thesefiles(fi).name)
    warning on

    disp('I will run ONLY ON FRAMES WHERE FLIES ARE SUPPOSELDY MISSING.')
    if nargin < 2
        StartFromHere = StartTracking;
    else
        StartFromHere = ForceStartFromHere;
    end
    TrackCore3;
end

function  [] = TrackCore3()
    InitialiseTracking;
            
    frame = StartFromHere;
    ff=PrepImage(movie,frame,mask);
    thresh = graythresh(ff);
    
    
    t = tic;
    
    disp('Movie has usable data starting from:')
    disp(StartTracking)
    disp('I will being tracking from:')
    disp(StartFromHere)
    if StartFromHere < StartTracking
        error('Cannot track here as this part of the movie is before StartTrackig')
    end
    
    for frame = StartFromHere:StopTracking  
        if any(flymissing(:,frame)) || any(flymissing(:,min(StopTracking,frame+1))) || any(isinf(posx(:,frame)))
            % redo analysis ONLY IF FLY IS MISSING
            % prep image

            ff=PrepImage(movie,frame,mask);


            % detect objects
            [rp] = DetectObjects(0,ff,thresh);

            % throw away small objects
            [rp] = DiscardSmallObjects(rp,min_area);


            % assign objects
            % special clear for Patch code
            posx(:,frame) = NaN; posy(:,frame) = NaN; area(:,frame) = NaN;
            orientation(:,frame) = NaN; heading(:,frame) = NaN;
            flymissing(:,frame) = 0; collision(:,frame) = 0;
            
            [posx,posy,orientation,heading,area,flymissing,collision] = AssignObjects3(frame,StartTracking,rp,posx,posy,orientation,heading,area,flymissing,DividingLine,collision);
            

            

            % find putative colliding flies
            for i = 1:narenas
                thisfly = 2*i;
                otherfly = 2*i-1;
                

                CollidingFly = FindPutativeCollidingFlies(i,collision,flymissing,frame,area);

                if mean(adjacency(otherfly:thisfly,frame-1)) &&  sum(flymissing(otherfly:thisfly,frame)) == 1
                    % override--flies adjacent in previous frame, and now
                    % one of them is missing? fishy.
                    CollidingFly=  [otherfly thisfly];
                end
                
                
                if ~isempty(CollidingFly)
                     % separate the putative colliding flies

                     % this is computationally expensive
                     [SeperationDifficulty, rp,posx,posy,area,orientation]=SplitCollidingFlies(CollidingFly,rp,posx,posy,area,orientation,ff,DividingLine,frame,thresh,adjacency);
                     if any(isinf(posx(:,frame)))
                         keyboard
                     end
                     if isinf(SeperationDifficulty)
                         adjacency(CollidingFly,frame)=1;
                         flymissing(CollidingFly,frame)=0;
                     else
                         collision(CollidingFly,frame)=0;
                         flymissing(CollidingFly,frame)=0;
                     end
                     
                     
  
                end
                

            end


            % detect Wing Extention

            [WingExtention] = DetectWingExtention(ff,frame,ROIs,posx,posy,area,rp,WingExtention,orientation,flymissing);


            % update display
            UpdateDisplay(v,frame,ff,flymissing,posx,posy,WingExtention,orientation,heading,t,StartFromHere,collision);
            
            % save
            % save every 1000 frames of data
            if  ~(ceil(frame/1000)-(frame/1000))
                disp('Saving...')
                save(thesefiles(fi).name,'posx','posy','orientation','adjacency','heading','flymissing','collision','area','WingExtention','-append')
                movie
            end

        
        else
           
            
        end
    end
    disp('Saving...')
    
    save(thesefiles(fi).name,'posx','posy','orientation','adjacency','heading','flymissing','collision','area','WingExtention','-append')
        
            
    
end

function [] = InitialiseTracking()
        disp('Initialising tracking....')
        % get movie parameters and initlaise movie reader
        movie = VideoReader(moviefile)
        % grab params and make placeholders
        h =  get(movie,'Height');
        w=get(movie,'Width');
        nframes = get(movie,'NumberOfFrames');
      
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


end
    



