% return trajectories
% Track3.m
% this is the actual engine of the tracking code
% this uses some metadata manually entereed about each movie file to
% process movies. this is meant to be run in the background, or when user
% attention is not required. 
% created by Srinivas Gorur-Shandilya at 19:56 , 29 August 2013. Contact me
% at http://srinivas.gs/contact/
% Track3 is a large re-write of Track2 where all the subfunctions have been
% split up into smaller files for better sanity of debugging.
function [] = Track4(v,ForceStartFromHere)
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
    Channel = 1;
    
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
    adjacency = []; 
    MajorAxis = [];
    MinorAxis = [];
    LookingAtOtherFly = [];
    WingExtention = [];
   
    % housekeeping
    displayfigure= [];
    fps = [];
    

    disp('Loading new file....')
    disp(thesefiles(fi).name)
    warning off
    load(thesefiles(fi).name)
    warning on
    if nargin < 2
        StartFromHere = [];
    else
        StartFromHere = ForceStartFromHere;
    end
    
    if ~isempty(posx)
        if ~any(isnan(posx(:,StopTracking-1)))
            % fully analysed
            if nargin == 1
                disp('This file looks fully analysed. I will skip this...')
            else
                if StartFromHere == 0
                    disp('File fully analysed, BUT Trashing all old data and re-starting...')
                   
                    StartFromHere = StartTracking;
                    TrackCore3;
                else
                    disp('File fully analysed, but Starting from specified location...')
                    TrackCore3;
                end
                
            end  
        else
            % not fully analysed. maybe partially analysed?
            % start from where you stopped before
            if StartFromHere == 0
                StartFromHere = StartTracking;
                disp('Partially analysed file; Trashing all old data and re-starting...')
                TrackCore3;
            else
                if nargin == 2
                    disp('Partially analysed file; but will start from :')
                    disp(StartFromHere)
                    TrackCore3;
                else
                    disp('Partially analysed file; will continue where I left off...')
                    StartFromHere= find(isnan(posx(1,:))==0,1,'last');
                    disp('...and that is:')
                    disp(StartFromHere)
                    TrackCore3;
                end
            end
        end
    else
        % new file.
        disp('This looks like a new file. Will start from the beginning:')
        disp(StartTracking)
        % get movie parameters and initlaise movie reader
        movie = VideoReader(moviefile)
        % grab params and make placeholders
        h =  get(movie,'Height');
        w=get(movie,'Width');
        nframes = get(movie,'NumberOfFrames');
        posx = NaN(n,nframes);
        posy = NaN(n,nframes);
        orientation = NaN(n,nframes);
        collision = zeros(n,nframes);
        adjacency = zeros(n,nframes);
        flymissing = zeros(n,nframes);
        MajorAxis = zeros(n,nframes);
        MinorAxis = zeros(n,nframes);
        LookingAtOtherFly = zeros(n,nframes);
        WingExtention = zeros(n,nframes);
        heading = NaN(n,nframes);
        allflies= 1:n;
        StartFromHere =StartTracking;
        %try
            TrackCore3;
        % catch
        %    disp('Something wrong with tracking. I will try the next file.')
        %    msubject= ('Track 4 failed somewhere');
        %    mbody = moviefile;
        %    sendmail('track4crash@srinivas.gs',msubject,mbody);
        %     % something wrong somewhere in the tracking. move on to the next file
        % end
    end
end

function  [] = TrackCore3()
    InitialiseTracking;
            
    frame = StartFromHere;

    ff=PrepImage(movie,frame,mask,Channel);
    thresh = graythresh(ff);
    
    
    t = tic;
    
    disp('Movie has usable data starting from:')
    disp(StartTracking)
    disp('I will being tracking from:')
    disp(StartFromHere)
    if StartFromHere < StartTracking
        error('Cannot track here as this part of the movie is before StartTrackig')
    end
    flylimits = zeros(2,n);
    for frame = StartFromHere:StopTracking  
        % prep image
        
        ff=PrepImage(movie,frame,mask,Channel);
        
        
        % detect objects
        [rp] = DetectObjects(0,ff,thresh);
        
        % throw away small objects
        [rp] = DiscardSmallObjects(rp,min_area);

        
        % assign objects
        [posx,posy,orientation,area,flymissing,collision,MajorAxis,MinorAxis] = AssignObjects4(frame,StartTracking,rp,posx,posy,orientation,area,flymissing,DividingLine,collision,MajorAxis,MinorAxis);

        
        
        if length(rp) == n
            % learn fly sizes
            if mean(area(:,frame)) > 100 && mean(area(:,frame)) < 2000
                % sounds reasonable
                min_area = (min_area + mean(area(:,frame))/3)/2;
            end
        end
        
        
        % find putative colliding flies

        if frame - StartFromHere > 6
            for i = 1:narenas
                thisfly = 2*i;
                otherfly = 2*i-1;
                % find colliding flies
                CollidingFly = FindPutativeCollidingFlies(i,collision,flymissing,frame,area);

                if mean(adjacency(otherfly:thisfly,frame-1)) &&  sum(flymissing(otherfly:thisfly,frame)) == 1
                    % override--flies adjacent in previous frame, and now
                    % one of them is missing? fishy.
                    CollidingFly=  [otherfly thisfly];
                end

                if ~isempty(CollidingFly)
                     % separate the putative colliding flies
                     [SeperationDifficulty, rp,posx,posy,area,orientation,MajorAxis,MinorAxis]=SplitCollidingFlies(CollidingFly,rp,posx,posy,area,orientation,ff,DividingLine,frame,thresh,adjacency,MajorAxis,MinorAxis);
                     if isinf(SeperationDifficulty)
                         adjacency(CollidingFly,frame)=1;
                         flymissing(CollidingFly,frame)=0;
                     else
                         collision(CollidingFly,frame)=0;
                         flymissing(CollidingFly,frame)=0;
                     end


                end

            end

        end


        % some fixes
        [orientation,heading,theseflies,flylimits] = FindHeadingsAndFixOrientations(frame,StartTracking,rp,posx,posy,orientation,heading,flymissing,ff,flylimits,MajorAxis,MinorAxis);

        LookingAtOtherFly(:,frame) = IsFlyLookingAtOtherFly(LookingAtOtherFly(:,frame-1),posx(:,frame),posy(:,frame),MajorAxis(:,frame),MinorAxis(:,frame),orientation(:,frame));

        % detect Wing Extension
        [WingExtention,flylimits] = DetectWingExtention4(theseflies,frame,ROIs,posx,posy,area,WingExtention,flymissing,flylimits,MajorAxis,MinorAxis, LookingAtOtherFly);
        
        
        % update display
        UpdateDisplay4(v,frame,ff,flymissing,posx,posy,WingExtention,orientation,heading,t,StartFromHere,collision,MajorAxis,MinorAxis,LookingAtOtherFly,displayfigure);



        
        % save
        % save every 1000 frames of data
        if  ~(ceil(frame/1000)-(frame/1000))
            disp('Saving...')
            save(thesefiles(fi).name,'posx','posy','orientation','adjacency','heading','flymissing','collision','area','WingExtention','MajorAxis','MinorAxis','-append')
            movie
        end
        
        
        
        
    end
    save(thesefiles(fi).name,'posx','posy','orientation','adjacency','heading','flymissing','collision','area','WingExtention','MajorAxis','MinorAxis','-append')
        
            
    
end

function [] = InitialiseTracking()
        disp('Initialising tracking....')
        % get movie parameters and initlaise movie reader
        movie = VideoReader(moviefile)
        % grab params and make placeholders
        h =  get(movie,'Height');
        w=get(movie,'Width');
        nframes = get(movie,'NumberOfFrames');
        % wipe all info from StartFromHere onwards
        
        
        posx(:,StartFromHere:end) = NaN;
        posy(:,StartFromHere:end) = NaN;
        orientation(:,StartFromHere:end) = NaN;
        collision(:,StartFromHere:end) = 0;
        adjacency(:,StartFromHere:end) = 0;
        flymissing(:,StartFromHere:end) = 0;
        MajorAxis(:,StartFromHere:end) = 0;
        MinorAxis(:,StartFromHere:end) = 0;
        LookingAtOtherFly(:,StartFromHere:end) = 0;
        WingExtention(:,StartFromHere:end) = 0;
        heading(:,StartFromHere:end) = NaN;
        allflies= 1:n;
        
        
        % build logical array of ROIs
        ff = read(movie,StartTracking);
        mask = ROI2mask(ff,ROIs);
        
        if v
            % create a display
            scrsz = get(0,'ScreenSize');
            displayfigure=figure('Position',[100 scrsz(4)/2 2*scrsz(3)/3 2*scrsz(4)/3]); hold on
            imagesc(ff), hold on
        end
end


end
    



