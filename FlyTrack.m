% FlyTrack.m
% created by Srinivas Gorur-Shandilya at 13:46 , 28 August 2013. Contact me
% at http://srinivas.gs/contact/
% FlyTrack.m is a master GUI that is meant to annotate fly movies with
% information that a tracking algo can use to automatically track fly
% trajectories. 
function []  = FlyTrack()
%% global parameters
global n
n = 4; % number of flies
startframe = 1;
narenas = 2;
frame = 1; % current frame
StartTracking = [];
StopTracking  = [];
LeftStart = [];
RightStart = [];
DividingLine = [];
ROIs=  []; % each row has 3 elements. the first is x cood of circle, the second is y, and the third is the radius

moviefigure= [];
f1=  [];
framecontrol = [];
framecontrol2= [];
threshcontrol = [];
showthreshcontrol=[];
markstartbutton = [];
markstopbutton = [];
markleftbutton =[];
markrightbutton  =[];
marklinebutton = [];
markroibutton = [];
nextfilebutton = [];

nframes=  [];
h = [];
movie = [];
mi= [];
moviefile= [];


%% choose files
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
mi=1;
InitialiseAnnotate(mi);


    


%% make GUI function

    function [] = CreateGUI(eo,ed)
        titletext = thesefiles(mi).name;
        moviefigure = figure('Position',[250 250 900 600],'Name',titletext,'Toolbar','none','Menubar','none','NumberTitle','off','Resize','off','HandleVisibility','on');

        f1 = figure('Position',[50 50 1100 100],'Toolbar','none','Menubar','none','NumberTitle','off','Resize','on','HandleVisibility','on');
        %nfliescontrol = uicontrol(f1,'Position',[83 5 40 20],'Style','edit','String',mat2str(n),'Callback',@nfliescallback);
        %uicontrol(f1,'Position',[20 5 60 20],'Style','text','String','# flies');

        %narenascontrol = uicontrol(f1,'Position',[223 5 50 20],'Style','edit','String',mat2str(narenas),'Callback',@narenascallback);
        %uicontrol(f1,'Position',[160 5 60 20],'Style','text','String','# arenas');

        framecontrol = uicontrol(f1,'Position',[53 45 600 20],'Style','slider','Value',startframe,'Min',1,'Max',nframes,'SliderStep',[100/nframes 1000/nframes],'Callback',@framecallback);
        uicontrol(f1,'Position',[1 45 50 20],'Style','text','String','frame #');

        framecontrol2 = uicontrol(f1,'Position',[383 5 60 20],'Style','edit','String',mat2str(frame),'Callback',@frame2callback);
        uicontrol(f1,'Position',[320 5 60 20],'Style','text','String','frame #');


        markstartbutton = uicontrol(f1,'Position',[700 10 80 20],'Style','pushbutton','String','Mark Start','Callback',@markstart);
        markstopbutton = uicontrol(f1,'Position',[700 50 80 20],'Style','pushbutton','String','Mark Stop','Callback',@markstop);

        markleftbutton = uicontrol(f1,'Position',[800 10 100 20],'Style','pushbutton','String','Mark Left start','Callback',@markleft);
        markrightbutton = uicontrol(f1,'Position',[800 50 100 20],'Style','pushbutton','String','Mark Right start','Callback',@markright);

        marklinebutton = uicontrol(f1,'Position',[910 10 100 20],'Style','pushbutton','String','Mark Dividing Line','Callback',@markline);
        markroibutton = uicontrol(f1,'Position',[910 50 100 20],'Style','pushbutton','String','Mark Circles','Callback',@markroi);

        nextfilebutton = uicontrol(f1,'Position',[223 5 50 20],'Style','pushbutton','String','NextFile','Enable','off','Callback',@nextcallback);
    end

    function [] = nextcallback(eo,ed)
        if mi == length(thesefiles)
            delete(moviefigure)
            delete(f1)
        else
            mi = mi+1;
            movie = VideoReader(thesefiles(mi).name);
            h =  get(movie,'Height');

            % working variables
            nframes = get(movie,'NumberOfFrames');
            
            % clear variables
            frame=1;
            markroi; % clears ROIs
            markline; % clears dividing line
            markstart;
            markstop;
            markleft;
            markright;
            
            delete(framecontrol)
            framecontrol = uicontrol(f1,'Position',[53 45 600 20],'Style','slider','Value',startframe,'Min',1,'Max',nframes,'SliderStep',[100/nframes 1000/nframes],'Callback',@framecallback);
        
            
            % update GUI
             titletext = thesefiles(mi).name;
             set(moviefigure,'Name',titletext);
             set(framecontrol,'Value',1);
             set(framecontrol2,'String','1')
            
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
                [he]=imellipse();
                position = wait(he);
                [cx,cy,cr]=circfit(position(:,1),position(:,2)); % horrible hack. I'm ashamed of this. 
                ROIs(:,i) = [cx cy cr];
            end
            drawline;
            set(markroibutton,'String','ROIs marked','BackgroundColor',[0.7 0 0])
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
        ff = 255-ff(:,:,1);
        figure(moviefigure), axis image
        imshow(ff);
        axis equal
        title(frame)
        drawline;
        savetrackdata;
        % try to draw the circles
        if ~isempty(ROIs)
            viscircles(ROIs(1:2,:)',ROIs(3,:),'EdgeColor','r');
        end
    end



    function  [] = markstart(eo,ed)
        if isempty(StartTracking)
            StartTracking = frame;
            set(markstartbutton,'String','start marked','BackgroundColor',[0.7 0 0])
        else
            StartTracking = [];
            set(markstartbutton,'String','Mark start','BackgroundColor',[1 1 1])
        end
        savetrackdata;
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

    function [] = markline(eo,ed)
        if isempty(DividingLine)
            figure(moviefigure)
            [x,y]=ginput(1);
            DividingLine = x;
            drawline;
            set(marklinebutton,'String','Line marked','BackgroundColor',[0.7 0 0])
        else
            DividingLine = [];
            set(marklinebutton,'String','Mark dividing line','BackgroundColor',[1 1 1])
            showimage;
        end
        savetrackdata;
        
    end

    function [] = drawline(eo,ed)
        if ~isempty(DividingLine)
            line([DividingLine DividingLine],[1 h],'LineWidth',2);
        end
        savetrackdata;
    end

    function  [] = savetrackdata(eo,ed)
        moviefile = thesefiles(mi).name;
        filename = thesefiles(mi).name;
        save(strcat(filename(1:end-3),'mat'),'DividingLine','n','StartTracking','StopTracking','LeftStart','RightStart','narenas','moviefile','ROIs');
        if ~isempty(DividingLine) && ~isempty(n) && ~isempty(StartTracking) && ~isempty(StopTracking) && ~isempty(LeftStart) && ~isempty(RightStart) && ~isempty(ROIs)
            set(nextfilebutton,'Enable','on');
        else
            set(nextfilebutton,'Enable','off');
        end
        
    end

end