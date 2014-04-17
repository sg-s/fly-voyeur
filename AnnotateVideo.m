% AnnotateVideo.m
% created by Srinivas Gorur-Shandilya at 13:46 , 28 August 2013. Contact me
% at http://srinivas.gs/contact/
% AnnotateVideo.m is a master GUI that is meant to annotate fly movies with
% information that a tracking algo can use to automatically track fly
% trajectories. 
function []  = AnnotateVideo(source,thesefiles)
%% global parameters
global n
n = 2; % number of flies
startframe = 10;
narenas = 1;
frame = 10; % current frame
StartTracking = [];
StopTracking  = [];
LeftStart = [];
RightStart = [];
DividingLine = [];
ROIs=  []; % each row has 3 elements. the first is x cood of circle, the second is y, and the third is the radius
Channel = 3;
nframes=  [];
h = [];
movie = [];
mi= [];
moviefile= [];

% figure and object handles
moviefigure= [];
f1=  [];
framecontrol = [];
framecontrol2= [];
markstartbutton = [];
markstopbutton = [];
markleftbutton =[];
markrightbutton  =[];
markroibutton = [];
nextfilebutton = [];
cannotanalysebutton = [];
channelcontrol = [];
narenascontrol =[];
nfliescontrol = [];
th = []; % text handles, allowing rapid deletion







%% choose files
if nargin == 0
    source = cd;
    allfiles = uigetfile('*.avi','MultiSelect','on'); % makes sure only avi files are chosen
    if ~ischar(allfiles)
    % convert this into a useful format
    thesefiles = [];
    for fi = 1:length(allfiles)
        thesefiles = [thesefiles dir(strcat(source,oss,cell2mat(allfiles(fi))))];
    end
    else
        thesefiles(1).name = allfiles;
    end
else
    cd(source)
end


mi=1;
InitialiseAnnotate(mi);
skip=0;

    


%% make GUI function

    function [] = CreateGUI(eo,ed)
        titletext = thesefiles(mi).name;
        moviefigure = figure('Position',[150 250 900 600],'Name',titletext,'Toolbar','none','Menubar','none','NumberTitle','off','Resize','off','HandleVisibility','on');

        f1 = figure('Position',[70 70 1100 100],'Toolbar','none','Menubar','none','NumberTitle','off','Resize','on','HandleVisibility','on');


        narenascontrol = uicontrol(f1,'Position',[60 5 50 20],'Style','edit','String',mat2str(narenas),'Callback',@narenascallback);
        uicontrol(f1,'Position',[5 5 60 20],'Style','text','String','# arenas');

        framecontrol = uicontrol(f1,'Position',[53 45 600 20],'Style','slider','Value',startframe,'Min',7,'Max',nframes,'SliderStep',[100/nframes 1000/nframes],'Callback',@framecallback);
        th(1)=uicontrol(f1,'Position',[1 45 50 20],'Style','text','String','frame #');

        framecontrol2 = uicontrol(f1,'Position',[383 5 60 20],'Style','edit','String',mat2str(frame),'Callback',@frame2callback);
        th(2)=uicontrol(f1,'Position',[320 5 60 20],'Style','text','String','frame #');

        channelcontrol = uicontrol(f1,'Position',[503 5 60 20],'Style','edit','String','3');
        th(3)=uicontrol(f1,'Position',[450 5 60 20],'Style','text','String','channel #');

        nfliescontrol = uicontrol(f1,'Position',[603 5 60 20],'Style','edit','String',mat2str(n),'Callback',@nfliescallback);
        th(4)=uicontrol(f1,'Position',[550 5 60 20],'Style','text','String','#flies');


        markstartbutton = uicontrol(f1,'Position',[700 10 80 20],'Style','pushbutton','String','Mark Start','Callback',@markstart);
        markstopbutton = uicontrol(f1,'Position',[700 50 80 20],'Style','pushbutton','String','Mark Stop','Callback',@markstop);

        markleftbutton = uicontrol(f1,'Position',[800 10 100 20],'Style','pushbutton','String','Mark Left start','Callback',@markleft);
        markrightbutton = uicontrol(f1,'Position',[800 50 100 20],'Style','pushbutton','String','Mark Right start','Callback',@markright);


        markroibutton = uicontrol(f1,'Position',[910 50 100 20],'Style','pushbutton','String','Mark Circles','Callback',@markroi);

        nextfilebutton = uicontrol(f1,'Position',[223 5 50 20],'Style','pushbutton','String','NextFile','Enable','on','Callback',@nextcallback);

        skipthisbutton = uicontrol(f1,'Position',[123 5 50 20],'Style','pushbutton','String','Skip This','Enable','on','Callback',@cannotanalysecallback);
    end

    function [] = cannotanalysecallback(eo,ed)
        % move this to cannot-analyse
        if exist('cannot-analyse') == 7

        else
            % make it
            mkdir('cannot-analyse')
        end
        % move this file there
        movefile(thesefiles(mi).name,strcat('cannot-analyse',oss,thesefiles(mi).name))
        % delete the .mat
        thisfile = thesefiles(mi).name;
        delete(strcat(thisfile(1:end-3),'mat'))
        % go to the next file
        skip=1;
        nextcallback;
        skip=0;
        


    end

    function [] = nfliescallback(eo,ed)
        
        n = str2num(get(nfliescontrol,'String'));

    end

    function [] = narenascallback(eo,ed)
        
        narenas = str2num(get(narenascontrol,'String'));

    end


    function [] = nextcallback(eo,ed)
        if mi == length(thesefiles)
            delete(moviefigure)
            delete(f1)
        else
            % clear all old variables
            disp('OK. Next file.')
            

            % delete all GUI elements
            delete(framecontrol)
            delete(framecontrol2)
            delete(channelcontrol)
            delete(nfliescontrol)
            delete(markroibutton)
            delete(markstartbutton)
            delete(markstopbutton)
            delete(markleftbutton)
            delete(markrightbutton)
            delete(nextfilebutton)
            delete(th(1),th(2),th(3),th(4));
            delete(moviefigure,f1)

            % redraw entire GUI
            CreateGUI;

            nframes=  [];
            h = [];
            moviefile= [];

            
            mi = mi+1;
            movie = VideoReader(thesefiles(mi).name);
            h =  get(movie,'Height');

            % working variables
            nframes = get(movie,'NumberOfFrames');
            
            % clear variables
            if ~skip
                frame=1;
                markroi; % clears ROIs
                markstart;
                markstop;
                markleft;
                markright;
            end
            
            startframe = 10;
            frame = 10; % current frame
            StartTracking = [];
            StopTracking  = [];
            LeftStart = [];
            RightStart = [];
            DividingLine = [];
            ROIs=  []; % each row has 3 elements. the first is x cood of circle, the second is y, and the third is the radius
            
            delete(framecontrol)

            framecontrol = uicontrol(f1,'Position',[53 45 600 20],'Style','slider','Value',startframe,'Min',7,'Max',nframes,'SliderStep',[100/nframes 1000/nframes],'Callback',@framecallback);
        
            
            % update GUI
            titletext = thesefiles(mi).name;
            set(moviefigure,'Name',titletext);
            set(framecontrol,'Value',10);
            set(framecontrol2,'String','10')
            
            showimage;
            
        end
    end


%% intialise function

    function [] = InitialiseAnnotate(mi)

        
        movie = VideoReader(thesefiles(mi).name);
        h =  get(movie,'Height');

        % working variables
        nframes = get(movie,'NumberOfFrames');
        
        CreateGUI;


        showimage;

    end


  
%% callback functions


    function [] = markroi(eo,ed)

        if isempty(ROIs)
            ROIs = NaN(3,narenas);
            figure(moviefigure), axis image

            for i = 1:narenas
                [he]=imellipse('PositionConstraintFcn',@(pos) [pos(1) pos(2) max(pos(3:4)) max(pos(3:4))]);
                position = wait(he);
                [cx,cy,cr]=circfit(position(:,1),position(:,2)); % horrible hack. I'm ashamed of this. 
                ROIs(:,i) = [cx cy cr];
            end
            
            set(markroibutton,'String','ROIs marked','BackgroundColor',[0.7 0 0])

            if narenas == 2
                % now automatically draw a line b/w the two arenas
                DividingLine = mean(ROIs(1,:));
                drawline;
            end


        else
            ROIs= [];
            set(markroibutton,'String','Mark circles','BackgroundColor',[1 1 1])
            showimage;
        end
        savetrackdata;

    end

function [] = framecallback(eo,ed)
    frame = ceil((get(framecontrol,'Value')));
    showimage();
    set(framecontrol2,'String',mat2str(frame));
end


function [] = frame2callback(eo,ed)
    
    frame = ceil(str2double(get(framecontrol2,'String')));
    showimage();    
    set(framecontrol,'Value',(frame));
end

    function [] = showimage(eo,ed)
        ff = read(movie,frame);
        Channel = str2num(get(channelcontrol,'String'));
        
        ff = 255-ff(:,:,Channel);
        figure(moviefigure), axis image
        imagesc(ff); colormap(gray)
        axis equal
        axis tight
        title(frame)
        drawline;
        savetrackdata;
        % try to draw the circles
        if ~isempty(ROIs)
            viscircles(ROIs(1:2,:)',ROIs(3,:),'EdgeColor','r');
        end
    end



    function  [] = markstart(eo,ed)
        if ~isempty(StartTracking)
            StartTracking = [];
            set(markstartbutton,'String','Mark start','BackgroundColor',[1 1 1])
            
        else
            
            StartTracking = frame;
            set(markstartbutton,'String','start marked','BackgroundColor',[0.7 0 0])
        

            % check if we can find 4 flies here
            disp('Validating start tracking location...')
            ff = read(movie,StartTracking);
            Channel = str2num(get(channelcontrol,'String'));
            mask = ROI2mask(ff,ROIs);
            

            ff2=PrepImage(movie,StartTracking,mask,Channel);
            thresh = graythresh(ff2);

            % detect objects
            [rp] = DetectObjects(0,ff2,thresh);

            % throw away small objects
            [rp] = DiscardSmallObjects(rp,400);



            if length(rp) == n
                % OK
                savetrackdata;
                figure(moviefigure), axis image
                hold on
                for i = 1:n
                    scatter(rp(i).Centroid(1),rp(i).Centroid(2),'g','filled')
                end

                % now that you have found the correct number of objects, see if you can see spots on the flies
                ff2 = ff(:,:,2) - ff(:,:,1);
                ff2 = ff2.*mask;
                objectIDs = MatchSpots2Objects(ff2,rp);

                if ~isempty(objectIDs)
                    % mark the spots we find
                    for i = objectIDs
                       scatter(rp(i).Centroid(1),rp(i).Centroid(2),1500,'r')
                       scatter(rp(i).Centroid(1),rp(i).Centroid(2),1600,'r') 
                    end
                end


            else
                % not OK
                beep
                disp('I cannot find n objects in this frame.')
                StartTracking = [];
                set(markstartbutton,'String','Mark start','BackgroundColor',[1 1 1])
                figure(moviefigure), axis image
                hold on
                for i = 1:length(rp)
                    scatter(rp(i).Centroid(1),rp(i).Centroid(2),'r','filled')
                end
            end
        end

        
    end

    function  [] = markstop(eo,ed)
        if isempty(StopTracking)
            StopTracking = frame;
            set(markstopbutton,'String','stop marked','BackgroundColor',[0.7 0 0])
        else
            StopTracking = [];
            set(markstopbutton,'String','Mark stop','BackgroundColor',[1 1 1])
        end
        savetrackdata;
    end

    function  [] = markleft(eo,ed)
        if isempty(LeftStart)
            LeftStart = frame;
            set(markleftbutton,'String','left marked','BackgroundColor',[0.7 0 0])
        else
            LeftStart = [];
            set(markleftbutton,'String','Mark left start','BackgroundColor',[1 1 1])
        end
        savetrackdata;
    end

    function  [] = markright(eo,ed)
        if isempty(RightStart)
            RightStart = frame;
            set(markrightbutton,'String','Right marked','BackgroundColor',[0.7 0 0])
        else
            RightStart = [];
            set(markrightbutton,'String','Mark right start','BackgroundColor',[1 1 1])
        end
        savetrackdata;
    end

    % this function no longer needed as lines are autoamtically calcualted
    % function [] = markline(eo,ed)
    %     if isempty(DividingLine)
    %         figure(moviefigure)
    %         [x,y]=ginput(1);
    %         DividingLine = x;
    %         drawline;
    %         set(marklinebutton,'String','Line marked','BackgroundColor',[0.7 0 0])
    %     else
    %         DividingLine = [];
    %         set(marklinebutton,'String','Mark dividing line','BackgroundColor',[1 1 1])
    %         showimage;
    %     end
    %     savetrackdata;
        
    % end

    function [] = drawline(eo,ed)
        if ~isempty(DividingLine)
            line([DividingLine DividingLine],[1 h],'LineWidth',2);
        end
        savetrackdata;
    end

    function  [] = savetrackdata(eo,ed)
        Channel = str2num(get(channelcontrol,'String'));
        moviefile = thesefiles(mi).name;
        filename = thesefiles(mi).name;
        save(strcat(filename(1:end-3),'mat'),'DividingLine','n','StartTracking','StopTracking','LeftStart','RightStart','narenas','moviefile','ROIs','Channel');
        if ~isempty(n) && ~isempty(StartTracking) && ~isempty(StopTracking) && ~isempty(LeftStart) && ~isempty(RightStart) && ~isempty(ROIs)
            set(nextfilebutton,'Enable','on');
        else
            set(nextfilebutton,'Enable','off');
        end
        
    end

end