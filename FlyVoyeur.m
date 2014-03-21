% FlyVoyeur
% wrapper function that calls all other functions and handles the tracking. 
% 
function [] = FlyVoyeur()
versionname = 'FlyVoyeur v1.0';

% global variables
folder_name = '';
matfiles = [];
videofiles = [];
FoundFilesList = {};

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


fig = figure('position',[50 50 450 740], 'Toolbar','none','Menubar','none','Name',versionname,'NumberTitle','off','IntegerHandle','off');

ChooseFolderButton = uicontrol(fig, 'Position',[10 700  150 30],'Style','pushbutton','String','Choose Folder...','Enable','on','FontSize',16,'Callback',@ChooseFolderCallback);
ThisFolder = uicontrol(fig, 'Position',[170 705  250 20],'Style','text','String','No folder chosen.','Enable','on','FontSize',16);
FileTypes = {'Needs Conversion','Raw Video','Annotated Video','Partially Tracked','Fully Tracked'};
FileTypeControl = uicontrol(fig,'Position',[10 665 420 30],'Style', 'popupmenu', 'String', FileTypes,'FontSize',16, 'value', 1,'Callback',@FileTypeCallback,'Visible','on');
FileBox = uicontrol(fig,'Position',[10 365 420 290],'Style','listbox','Min',0,'Max',2,'String',FoundFilesList,'FontSize',16,'Callback',@FoundFilesCallback);

% buttons
ConvertVideoButton = uicontrol(fig, 'Position',[20 295 200 50],'Style','pushbutton','String','Convert Video','Enable','on','FontSize',20,'Callback',@ConvertVideoCallback,'Visible','on');
AnnotateVideoButton = uicontrol(fig, 'Position',[230 295  200 50],'Style','pushbutton','String','Annotate Video','Enable','on','FontSize',20,'Callback',@AnnotateVideoCallback,'Visible','on');
EstimateTimeButton = uicontrol(fig, 'Position',[20 235 200 50],'Style','pushbutton','String','Estimate Running Time','Enable','on','FontSize',14,'Callback',@EstimateTimeCallback,'Visible','on');
BatchTask = uicontrol(fig, 'Position',[230 235  200 50],'Style','pushbutton','String','Split into Batches','Enable','on','FontSize',20,'Callback',@BatchTaskCallback,'Visible','on');

TrackButton = uicontrol(fig, 'Position',[20 175 410 50],'Style','pushbutton','String','TRACK!','Enable','on','FontSize',25,'Callback',@TrackCallback,'Visible','on');
ShowTrackingButton = uicontrol(fig, 'Position',[20 115  200 50],'Style','pushbutton','String','Show Tracking Info','Enable','on','FontSize',16,'Callback',@BatchTaskCallback,'Visible','on');
ScoreTrackingButton = uicontrol(fig, 'Position',[230 115  200 50],'Style','pushbutton','String','Score Tracking','Enable','on','FontSize',20,'Callback',@BatchTaskCallback,'Visible','on');


function [folder_name] = ChooseFolderCallback(eo,ed)
	folder_name = uigetdir(cd,'Choose the folder where the videos are...');
	set(ThisFolder,'String',folder_name);

	% look for MAT files in the folder. 
	matfiles = dir(strcat(folder_name,oss,'*.mat'));
	

	% look for video files without mat files


end


end