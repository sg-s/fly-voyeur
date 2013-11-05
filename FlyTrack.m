% FlyTrack.m
% created by Srinivas Gorur-Shandilya at 13:46 , 28 August 2013. Contact me
% at http://srinivas.gs/contact/
% FlyTrack.m is a master GUI that is meant to annotate fly movies with
% information that a tracking algo can use to automatically track fly
% trajectories. 
function []  = FlyTrack()
%% global parameters
n = 4; % number of flies
min_area = 100; % minimum area for a fly
startframe = 1;
narenas = 2;
frame = 1; % current frame
thresh = 100; % from 0 to 255
StartTracking = [];
StopTracking  = [];
LeftStart = [];
RightStart = [];
DividingLine = [];
ROIs=  []; % each row has 3 elements. the first is x cood of circle, the second is y, and the third is the radius
wings= []; % stores pixel intensity of wing picels. rough estimate.
body = []; % stores pixel intensity of body pixels

%% choose file
filename = uigetfile('*');

% process
movie = VideoReader(filename);
h =  get(movie,'Height');

% working variables
nframes = get(movie,'NumberOfFrames');
posx = NaN(n,nframes);
posy = posx;
%% create gui
moviefigure = figure('Position',[250 250 900 600],'Toolbar','none','Menubar','none','NumberTitle','off','Resize','off','HandleVisibility','on');

f1 = figure('Position',[50 50 1100 100],'Toolbar','none','Menubar','none','NumberTitle','off','Resize','on','HandleVisibility','on');
nfliescontrol = uicontrol(f1,'Position',[83 5 40 20],'Style','edit','String',mat2str(n),'Callback',@nfliescallback);
uicontrol(f1,'Position',[20 5 60 20],'Style','text','String','# flies');

narenascontrol = uicontrol(f1,'Position',[223 5 50 20],'Style','edit','String',mat2str(narenas),'Callback',@narenascallback);
uicontrol(f1,'Position',[160 5 60 20],'Style','text','String','# arenas');

framecontrol = uicontrol(f1,'Position',[53 45 600 20],'Style','slider','Value',startframe,'Min',1,'Max',nframes,'SliderStep',[100/nframes 1000/nframes],'Callback',@framecallback);
uicontrol(f1,'Position',[1 45 50 20],'Style','text','String','frame #');

framecontrol2 = uicontrol(f1,'Position',[383 5 60 20],'Style','edit','String',mat2str(frame),'Callback',@frame2callback);
uicontrol(f1,'Position',[320 5 60 20],'Style','text','String','frame #');

threshcontrol = uicontrol(f1,'Position',[543 5 60 20],'Style','edit','String',mat2str(thresh),'Callback',@threshcontrolcallback);
uicontrol(f1,'Position',[480 5 60 20],'Style','text','String','Threshold');
showthreshcontrol = uicontrol(f1,'Position',[643 5 60 20],'Style','checkbox','Value',1,'Callback',@checkboxcallback);

markstartbutton = uicontrol(f1,'Position',[700 10 80 20],'Style','pushbutton','String','Mark Start','Callback',@markstart);
markstopbutton = uicontrol(f1,'Position',[700 50 80 20],'Style','pushbutton','String','Mark Stop','Callback',@markstop);

markleftbutton = uicontrol(f1,'Position',[800 10 100 20],'Style','pushbutton','String','Mark Left start','Callback',@markleft);
markrightbutton = uicontrol(f1,'Position',[800 50 100 20],'Style','pushbutton','String','Mark right start','Callback',@markright);

marklinebutton = uicontrol(f1,'Position',[910 10 100 20],'Style','pushbutton','String','Mark Dividing Line','Callback',@markline);
markroibutton = uicontrol(f1,'Position',[910 50 100 20],'Style','pushbutton','String','Mark Circles','Callback',@markroi);


%% intialise
ff = read(movie,startframe);
figure(moviefigure)
bw = im2bw(ff,thresh/255);
ff(:,:,1) = ff(:,:,1)*0;
ff(:,:,1) = bw*255;
imshow(ff);


%% callback functions

    function [] = markwings(eo,ed)
        figure(moviefigure)
        [x,y]=(ginput(1));
        x = round(x); y = round(y);
        
        wings = [wings ff(y,x)];
        
    end

    function [] = markbody(eo,ed)
        figure(moviefigure)
        [x,y]=(ginput(1));
        x = round(x); y = round(y);
        body = [body ff(y,x)];
        
    end

    function [] = checkboxcallback(eo,ed)
        showimage;
    end

    function  [] = nfliescallback(eo,ed)
        n = floor(str2double(get(nfliescontrol,'String')));
        savetrackdata;
    end

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
        if get(showthreshcontrol,'Value')
            % separate wing, body and background
            % assign foreground to channgel 1
            bw = im2bw(ff,thresh/255);
            ff(:,:,1) = ff(:,:,1)*0;
            ff(:,:,1) = bw*255;
            

            
            
        else
        end
        
        imshow(ff);
        title(frame)
        drawline;
        savetrackdata;
    end

    function  [] = threshcontrolcallback(eo,ed)
        thresh = str2double(get(threshcontrol,'String'));
        showimage;
        savetrackdata;
    end

    function [] = narenascallback(eo,ed)
        narenas = round(str2double(get(narenascontrol,'String')));
        savetrackdata;
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
        moviefile = filename;
        thresh = thresh/255;
        save(strcat(filename(1:end-3),'mat'),'DividingLine','n','StartTracking','StopTracking','LeftStart','RightStart','thresh','narenas','moviefile','ROIs');
        thresh = thresh*255; 
    end

end