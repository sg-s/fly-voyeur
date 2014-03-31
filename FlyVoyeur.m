% FlyVoyeur
% wrapper function that calls all other functions and handles the tracking. 
% 
function [] = FlyVoyeur()
VersionName = 'FlyVoyeur v_11_';



% check for internal dependencies
dependencies = {'oval','strkat','PrettyFig','CheckForNewestVersionOnBitBucket','triangle','oss'};
for i = 1:length(dependencies)
    if exist(dependencies{i}) ~= 2
        error('Kontroller is missing an external function that it needs to run. You can download it <a href="https://bitbucket.org/srinivasgs/srinivas.gs_mtools">here.</a>')
    end
end
clear i

% check for new version of Kontroller
try
    CheckForNewestVersionOnBitBucket(mfilename,VersionName)
end



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
global options
options.WingExtention = 1;
options.gpuAccelerate = 0;
options.ShowDisplay = 0;
options.Batches = 1;
options.parallel = 0;

% initialise
global ncores
ncores = feature('numCores');
for i = 1:(ncores)
	nBatchesString = [nBatchesString mat2str(i)];
end
clear i

% figure out where this script is
codepath = StripPath(mfilename('fullpath'));

% figure out if gpu Acceleration possible
try gpuArray(ones(1,10));
	options.gpuAccelerate = 1;
catch err
	if ~isempty(strfind(err.message,'No supported GPU'))
		disp('FlyVoyeur:gpu Acceleration is not supported on this device.')
	end
end

% figure out if parallel processing possible
try parpool('local');
	options.parallel = 1;
	delete(gcp)
catch err
	if strmatch(err.identifier,'MATLAB:UndefinedFunction')
		disp('FlyVoyeur:parallel workers are not supported on this device.')
	elseif strmatch(err.identifier,'parallel:convenience:ConnectionOpen')
		options.parallel = 1;
		delete(gcp)
	else
		disp('FlyVoyeur:parallel workers are not supported on this device.')
	end

end


fig = figure('position',[50 50 450 740], 'Toolbar','none','Menubar','none','Name',VersionName,'NumberTitle','off','IntegerHandle','off');

ChooseFolderButton = uicontrol(fig, 'Position',[10 700  150 30],'Style','pushbutton','String','Choose Folder...','Enable','on','FontSize',16,'Callback',@ChooseFolderCallback);
ThisFolder = uicontrol(fig, 'Position',[170 705  250 20],'Style','text','String','No folder chosen.','Enable','on','FontSize',16);
FileTypes = {'Needs Conversion','Needs Annotation','Annotated Video','Partially Tracked','Fully Tracked'};
FileTypeControl = uicontrol(fig,'Position',[10 665 420 30],'Style', 'popupmenu', 'String', FileTypes,'FontSize',16, 'value', 1,'Callback',@FileTypeCallback,'Visible','off');
FileBox = uicontrol(fig,'Position',[10 365 420 290],'Style','listbox','Min',0,'Max',2,'String',FoundFilesList,'FontSize',16,'Visible','off');

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

	DetermineVideoStatus(folder_name);
end

function [] = DetermineVideoStatus(folder_name)
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
	end

	% figure out other types of files
	converted_movies = setdiff(1:length(moviefiles),convert_these);
	for j = converted_movies
		% is there an associated .mat file?
		thismatfile = strcat(moviefiles(1).name(1:end-3),'mat');
		if ~isempty(matfiles)
			disp('148')
			keyboard
			DetermineNatureOfMATFiles(convert_these);
		else
			% obviously there is no associated mat file
			annotate_these = [annotate_these j];
			set(AnnotateVideoButton,'Visible','on');
			set(FileBox,'Visible','on');
			set(FileTypeControl,'Value',2,'Visible','on');
			set(FileBox,'String',{moviefiles(annotate_these).name});
		end
	end
	clear j
	
end

function  [] = DetermineNatureOfMATFiles()
	keyboard
end

function [] = FileTypeCallback(eo,ed)
	switch get(FileTypeControl,'Value')
	case 1
		% show videos that need to be converted
		if ~isempty(convert_these)
			set(FileBox,'String',{moviefiles(convert_these).name});
			set(ConvertVideoButton,'Visible','on');
		else
			set(FileBox,'String','No videos need to be converted.');
			set(ConvertVideoButton,'Visible','off');
		end
	case 2
		% show videos unannotated but converted videos
		if ~isempty(annotate_these)
			set(FileBox,'String',{moviefiles(annotate_these).name});
			set(AnnotateVideoButton,'Visible','on');
			set(ConvertVideoButton,'Visible','off');
		else
			set(FileBox,'String','No videos need to be annotated.');
			set(ConvertVideoButton,'Visible','off');
			set(AnnotateVideoButton,'Visible','off');
		end
		% hide convert video button


	case 3
		% show annotated, untracked videos
	case 4
		% show partially tracked videos
	case 5
		% show fully tracked videos
	end

end

function [] = ConvertVideoCallback(eo,ed)
	if ismac
		folder_name = get(ThisFolder,'String');
		h = waitbar(0.1,'Converting videos...');
		cd(folder_name)

		SwitchAllControls('off');

		if options.parallel
			% batch the tasks
			bn = min(length(convert_these),ncores);
			mext = moviefiles(convert_these(1)).name(end-3:end);
			BatchVideotask(bn,mext);
			% now convert them in parallel
			matlabpool open
			parfor pari = 1:bn
				% go to the folder
				cd(strcat('fv_batch',mat2str(pari)))
				% convert the videos there
				system(strkat(codepath,oss,'ConvertVideo.sh ',mext, ' MJPG avi avi'));
			end
			% unbatch
			UnBatch();
			matlabpool close
			
		else
			% move to the folder to be copied

			mext = moviefiles(convert_these(1)).name(end-3:end);
			system(strkat(codepath,oss,'ConvertVideo.sh ',mext, ' MJPG avi avi'))


		end
		waitbar(1,h);
		close(h)

		% update file discriptions
		annotate_these = [annotate_these convert_these];
		convert_these = [];

		% move back to the codepath
		cd(codepath)

		SwitchAllControls('on');
	else
		errordlg('Video conversion only supported on Mac OS X.')
	end


	
	
end

function [] = SwitchAllControls(state)
	set(ChooseFolderButton,'Enable',state)
	set(ThisFolder,'Enable',state)
	set(VerbosityControl,'Enable',state)
	set(BatchTask,'Enable',state)
	set(detectWE,'Enable',state)
	set(enableGPU,'Enable',state)
	set(nbatches,'Enable',state)
	set(ScoreTrackingButton,'Enable',state)
	set(TrackButton,'Enable',state)
	set(EstimateTimeButton,'Enable',state)
	set(ShowTrackingButton,'Enable',state)
	set(ThisFolder,'Enable',state)
	set(ChooseFolderButton,'Enable',state)
	set(AnnotateVideoButton,'Enable',state)
	set(ConvertVideoButton,'Enable',state)
	set(FileTypeControl,'Enable',state)
end

function [] = AnnotateVideoCallback(eo,ed)
	folder_name = get(ThisFolder,'String');
	AnnotateVideo(folder_name,moviefiles(annotate_these));
end



end