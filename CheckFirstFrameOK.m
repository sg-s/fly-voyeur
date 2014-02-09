% CheckFirstFrameOK.m
% checks that the first frame is OK, and that Track3 can find the right number of objects in it.

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

badfiles{1}= [];
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
    Channel=1;
    
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
        % look at first frame
        frame = StartTracking;
        movie = VideoReader(moviefile)
        % grab params and make placeholders
        h = get(movie,'Height');
        w = get(movie,'Width');
        nframes = get(movie,'NumberOfFrames');

        % build logical array of ROIs
        disp('Building ROI mask...')
        if ~isempty(StartTracking)
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

            ff=PrepImage(movie,frame,mask,Channel);
            thresh = graythresh(ff);

            % detect objects
            [rp] = DetectObjects(0,ff,thresh);

            % throw away small objects
            [rp] = DiscardSmallObjects(rp,min_area);

            if length(rp) == 4
                disp('All Good with this file')
            else
                disp('somthing wrong with this file. I WILL DELETE THIS ANNOTATION')

                delete(thesefiles(fi).name)
                % move the movie file to an -annotate this folder
                if exist('annotate-this') == 7
                else
                    mkdir('annotate-this')
                end
                disp('Moving file for re-annotation...')
                clear movie
                movefile(moviefile,strcat('annotate-this',oss,moviefile))
            end
        else
            % no annotation.
            delete(thesefiles(fi).name)
            % move the movie file to an -annotate this folder
            if exist('annotate-this') == 7
            else
                mkdir('annotate-this')
            end
            disp('Moving file for re-annotation...')
            clear movie
            badfiles{fi} = moviefile
            % movefile(moviefile,strcat('annotate-this',oss,moviefile))
        end


    end
    
    
end
disp('These files cannot be analysed:')
badfiles
     



