% FlyVoyeur
% wrapper function that calls all other functions and handles the tracking. 
% 
function [] = FlyVoyeur()
versionname = 'FlyVoyeur v1.1';


% dependeancies
% oss.m

% global variables
folder_name = '';
matfiles = [];
moviefiles = [];
convert_these = [];
annotate_these = [];
FoundFilesList = {};
nBatchesString = {};
movieformats = {'avi','MPG','mpg','AVI','mp4','m4v','MPEG','mpeg','mov'};

% handles
ChooseFolderButton = [];
ThisFolder = [];
fig = [];
FileTypeControl = [];
FileBox = [];
ConvertVideoButton = [];

% OPTIONS
options.WingExtention = 1;
options.gpuAccelerate = 1;
options.ShowDisplay = 0;
options.Batches = 1;

% initialise
ncores = feature('numCores');
for i = 1:(ncores)
	nBatchesString = [nBatchesString mat2str(i)];
end
clear i

% figure out if gpu Acceleration possible
gpuOK = 0;
try gpuArray(ones(1,10));
	gpuOK = 1;
catch err
	if ~isempty(strfind(err.message,'No supported GPU'))
		disp('gpu Acceleration is not supported on this device.')
	end
end


fig = figure('position',[50 50 450 740], 'Toolbar','none','Menubar','none','Name',versionname,'NumberTitle','off','IntegerHandle','off');

ChooseFolderButton = uicontrol(fig, 'Position',[10 700  150 30],'Style','pushbutton','String','Choose Folder...','Enable','on','FontSize',16,'Callback',@ChooseFolderCallback);
ThisFolder = uicontrol(fig, 'Position',[170 705  250 20],'Style','text','String','No folder chosen.','Enable','on','FontSize',16);
FileTypes = {'Needs Conversion','Raw Video','Annotated Video','Partially Tracked','Fully Tracked'};
FileTypeControl = uicontrol(fig,'Position',[10 665 420 30],'Style', 'popupmenu', 'String', FileTypes,'FontSize',16, 'value', 1,'Callback',@FileTypeCallback,'Visible','off');
FileBox = uicontrol(fig,'Position',[10 365 420 290],'Style','listbox','Min',0,'Max',2,'String',FoundFilesList,'FontSize',16,'Visible','off','Callback',@FoundFilesCallback);

% buttons
ConvertVideoButton = uicontrol(fig, 'Position',[20 295 200 50],'Style','pushbutton','String','Convert Video','Enable','on','FontSize',20,'Callback',@ConvertVideoCallback,'Visible','off');
AnnotateVideoButton = uicontrol(fig, 'Position',[230 295  200 50],'Style','pushbutton','String','Annotate Video','Enable','on','FontSize',20,'Callback',@AnnotateVideoCallback,'Visible','off');
EstimateTimeButton = uicontrol(fig, 'Position',[20 235 170 50],'Style','pushbutton','String','Estimate Running Time','Enable','on','FontSize',14,'Callback',@EstimateTimeCallback,'Visible','off');
BatchTask = uicontrol(fig, 'Position',[200 235  170 50],'Style','pushbutton','String','Split into Batches','Enable','on','FontSize',16,'Callback',@BatchTaskCallback,'Visible','off');
TrackButton = uicontrol(fig, 'Position',[20 55 410 50],'Style','pushbutton','String','TRACK!','Enable','on','FontSize',25,'Callback',@TrackCallback,'Visible','off');
ShowTrackingButton = uicontrol(fig, 'Position',[20 5  200 50],'Style','pushbutton','String','Show Tracking Info','Enable','on','FontSize',16,'Callback',@BatchTaskCallback,'Visible','off');
ScoreTrackingButton = uicontrol(fig, 'Position',[230 5  200 50],'Style','pushbutton','String','Score Tracking','Enable','on','FontSize',20,'Callback',@BatchTaskCallback,'Visible','off');


% other controls
nbatches = uicontrol(fig, 'Position',[375 235  70 50],'Style','popupmenu','String',nBatchesString,'Enable','on','FontSize',16,'Callback',@BatchTaskCallback,'Visible','off');
enableGPU = uicontrol(fig, 'Position',[15 95 270 50],'Style','checkbox','String','Enable GPU acceleration','Enable','on','FontSize',16,'Callback',@BatchTaskCallback,'Visible','off');
detectWE = uicontrol(fig, 'Position',[220 95 270 50],'Style','checkbox','String','Detect Wing Extension','Enable','on','FontSize',16,'Callback',@BatchTaskCallback,'Visible','off');
VerbosityControl = uicontrol(fig, 'Position',[15 120 270 50],'Style','checkbox','String','Show Display','Enable','on','FontSize',16,'Callback',@BatchTaskCallback,'Visible','off');



function [folder_name] = ChooseFolderCallback(eo,ed)
	folder_name = uigetdir(cd,'Choose the folder where the videos are...');
	set(ThisFolder,'String',folder_name);

	% look for MAT files in the folder. 
	matfiles = dir(strcat(folder_name,oss,'*.mat'));
	

	% look for video files
	moviefiles = [];
	
	for j = 1:length(movieformats)

		moviefiles=[moviefiles dir(strcat(folder_name,oss,'*.',movieformats{j}))'];
	end
	clear j

	% figure out which of these you can look at which you cant
	convert_these = [];
	for j = 1:length(moviefiles)
		try
		 	v = VideoReader(strcat(folder_name,oss,moviefiles(j).name));
		 	read(v,1);
		catch err
		 	convert_these = [convert_these j];
		end
		 
	end
	clear j

	% if there are any videos to be converted, alert the user. 
	if ~isempty(convert_these)
		set(ConvertVideoButton,'Visible','on');
		set(FileBox,'Visible','on');
		set(FileTypeControl,'Value',1,'Visible','on');
		set(FileBox,'String',{moviefiles(convert_these).name});
	else
		disp('write case where there are no videos to be converted.')
		keyboard
	end





end


end