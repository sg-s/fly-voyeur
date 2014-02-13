% ShowTracking.m
% shows the tracking done by track2, superimposed on the video.
%% choose files to show
function [] = ShowTracking(varargin)
source = cd;
if nargin == 0 
    allfiles = uigetfile('*.mat','MultiSelect','off'); % makes sure only annotated files are chosen
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
    thesefiles(1).name = varargin{1};
end

%% global vairables
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
spot =[];
rp = [];
displayfigure= [];
fps = [];
movie = [];
background = [];
t=[];
collision = [];
adjacency = [];
WingExtention = [];
pause = 0;
PauseButton = [];
CopulationTimes = [];
Copulation = [];
WingExtention = [];
MajorAxis = [];
MinorAxis = [];
LookingAtOtherFly = [];
wh = zeros(1,4); % handles for wing extension signal

frame = StartTracking; % current frame
Channel = 1;
%% load 
warning off
load(thesefiles(1).name)
warning on
movie = VideoReader(moviefile)
frame = StartTracking; % current frame
%% make the figure
f1 = figure('Position',[250 250 900 600],'Name',thesefiles(1).name,'Toolbar','none','Menubar','none','NumberTitle','off','Resize','off','HandleVisibility','on');


if isempty(StartTracking)
    error('StartTracking is empty. Are you sure this file is analysed/OK?')
end


if nargin == 2
    InitialValue = varargin{2};
else
    InitialValue = StopTracking;
end

framecontrol = uicontrol(f1,'Position',[110 47 690 20],'Style','slider','Value',InitialValue,'Min',1,'Max',StopTracking,'SliderStep',[0.001 0.1],'Callback',@framecallback);

gobackbutton = uicontrol(f1,'Position',[73 45 30 30],'Style','pushbutton','String','<','Callback',@gobackCallback);
goforwardbutton = uicontrol(f1,'Position',[813 45 30 30],'Style','pushbutton','String','>','Callback',@goforwardCallback);

NextWingButton= uicontrol(f1,'Position',[770 5 80 30],'Style','pushbutton','String','Wing >','Callback',@NextWingCallback);
PreviousWingButton= uicontrol(f1,'Position',[73 5 80 30],'Style','pushbutton','String','< Wing','Callback',@PreviousWingCallback);

NextCollisionButton= uicontrol(f1,'Position',[670 5 80 30],'Style','pushbutton','String','Collision >','Callback',@NextCollisionCallback);
PreviousCollisionButton= uicontrol(f1,'Position',[173 5 80 30],'Style','pushbutton','String','< Collision','Callback',@PreviousCollisionCallback);

PlayButton = uicontrol(f1,'Position',[473 5 80 30],'Style','togglebutton','String','PLAY','Value',0,'Callback',@PlayCallback);


framecontrol2 = uicontrol(f1,'Position',[383 5 60 20],'Style','edit','String',mat2str(frame),'Callback',@frame2callback);
uicontrol(f1,'Position',[320 5 60 20],'Style','text','String','frame #');

%% intialise
ff = read(movie,InitialValue);
figure(f1)
imshow(ff);
axis equal


%% callbacks

    function PlayCallback(eo,ed)
        if get(PlayButton,'Value')
            set(PlayButton,'String','Pause')
            while frame < StopTracking && get(PlayButton,'Value')
                
                frame=frame+1;
                set(framecontrol,'Value',(frame));
                set(framecontrol2,'String',mat2str(frame));
                showimage;
            end
        else
            set(PlayButton,'String','PLAY')
        end
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

function [] = gobackCallback(eo,ed)
    frame = ceil(str2double(get(framecontrol2,'String')));
    frame=max(1,frame-1);
    showimage();    
    set(framecontrol,'Value',(frame));
    set(framecontrol2,'String',mat2str(frame));
    
end

function [] = goforwardCallback(eo,ed)
    frame = ceil(str2double(get(framecontrol2,'String')));
    frame=min(StopTracking,frame+1);
    showimage();    
    set(framecontrol,'Value',(frame));
    set(framecontrol2,'String',mat2str(frame));
    
end

function [] = NextWingCallback(eo,ed)
    % goes to the next frame with a wing extension
    frame = ceil(str2double(get(framecontrol2,'String')));
    we=(logical(sum(WingExtention)));
    we(1:frame)=0;
    frame = find(we,1,'first');
    showimage();    
    set(framecontrol,'Value',(frame));
    set(framecontrol2,'String',mat2str(frame));
    
end

function [] = NextCollisionCallback(eo,ed)
    % goes to the next frame with a collision
    frame = ceil(str2double(get(framecontrol2,'String')));
    we=(logical(sum(collision)));
    we(1:frame)=0;
    frame = find(we,1,'first');
    showimage();    
    set(framecontrol,'Value',(frame));
    set(framecontrol2,'String',mat2str(frame));
    
end

function [] = PreviousWingCallback(eo,ed)
    % goes to the next frame with a wing extension
    frame = ceil(str2double(get(framecontrol2,'String')));
    we=(logical(sum(WingExtention)));
    we(frame:end)=0;
    frame = find(we,1,'last');
    showimage();    
    set(framecontrol,'Value',(frame));
    set(framecontrol2,'String',mat2str(frame));
    
end

function [] = PreviousCollisionCallback(eo,ed)
    % goes to the next frame with a wing extension
    frame = ceil(str2double(get(framecontrol2,'String')));
    we=(logical(sum(collision)));
    we(frame:end)=0;
    frame = find(we,1,'last');
    showimage();    
    set(framecontrol,'Value',(frame));
    set(framecontrol2,'String',mat2str(frame));
    
end

%% show image
function [] = showimage(eo,ed)
    cla
    ff = read(movie,frame);
    figure(f1), axis image
    imshow(ff);
    axis equal
    if frame > StartTracking && StopTracking
        for i = 1:n
            

            if flymissing(i,frame)
                scatter(posx(i,frame),posy(i,frame),'r','filled')

            else
                if LookingAtOtherFly(i,frame)
                    triangle([posx(i,frame) posy(i,frame)],orientation(i,frame),10,'k',3);
                else
                    triangle([posx(i,frame) posy(i,frame)],orientation(i,frame),10,'k');
                end

            end
            if abs(WingExtention(i,frame)) > 0
                text(posx(i,frame)-50,posy(i,frame)-50,oval(abs(WingExtention(i,frame)),2));
            end

        end
        cf = [];
        if any(WingExtention(:,frame))

            scatter(posx(find(WingExtention(:,frame)),frame),posy(find(WingExtention(:,frame)),frame),1500,'g')
            scatter(posx(find(WingExtention(:,frame)),frame),posy(find(WingExtention(:,frame)),frame),1600,'g')
            

        end
        if any(collision(:,frame))
            cf = mat2str(find(collision(:,frame)));
            title(strkat('Frame ', mat2str(frame),' Colliding flies:',cf));
        else
            title(strkat('Frame ', mat2str(frame)));
        end
    end
    
    if frame > StartTracking + 11
        % plot the tracks for the last 10 frames
        for i = 1:n
            plot(posx(i,frame-10:frame),posy(i,frame-10:frame),'r')
        end
    end

end


end