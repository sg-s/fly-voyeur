% return trajectories
% EestimateTrackingTime.m
% estimates the tracking time for selected videos.
% this is the actual engine of the tracking code
% this uses some metadata manually entereed about each movie file to
% process movies. this is meant to be run in the background, or when user
% attention is not required. 
% created by Srinivas Gorur-Shandilya at 19:56 , 29 August 2013. Contact me
% at http://srinivas.gs/contact/
% Track3 is a large re-write of Track2 where all the subfunctions have been
% split up into smaller files for better sanity of debugging.
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
%% core variables
totalnframes = zeros(1,length(thesefiles));
speed = 5; % how many frames per second will the code run at?
%%
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

    
    if ~isempty(posx)
        if ~any(isnan(posx(:,StopTracking-1)))
            % fully analysed
                disp('This file looks fully analysed. I will skip this...')
                StartTracking=0;
                StopTracking=0;
        else
            % not fully analysed. maybe partially anlysed?
            % start from where you stopped before
            disp('Partially analysed file; will continue where I left off...')
            StartTracking = find(isnan(posx(1,:))==0,1,'last');
               
        end
    else
        % new file.
        disp('This looks like a new file. Will start from the beginning:')
        disp(StartTracking)


    end
    
    try
        totalnframes(fi)=(StopTracking-StartTracking);
    catch
        disp('somthing wrong with this file. I WILL DELETE THIS ANNOTATION')
        delete(thesefiles(fi).name)
    end
    
end
 sr=sum(totalnframes)/speed;

 disp('Analyisis of these files estimated to finish at:')
 disp( datestr(datenum(now) + datenum(0,0,0,0,0,sr)))
     



