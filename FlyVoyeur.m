% FlyVoyeur
% wrapper function that calls all other functions and handles the tracking. 
% 
function [] = FlyVoyeur()
versionname = 'FlyVoyeur v1.0';

% global variables
folder_name = '';

% handles
ChooseFolderButton = [];
ThisFolder = [];
fig = [];


fig = figure('position',[50 50 450 740], 'Toolbar','none','Menubar','none','Name',versionname,'NumberTitle','off','IntegerHandle','off');

ChooseFolderButton = uicontrol(fig, 'Position',[10 700  150 30],'Style','pushbutton','String','Choose Folder...','Enable','on','FontSize',16,'Callback',@ChooseFolderCallback);
ThisFolder = uicontrol(fig, 'Position',[170 705  250 20],'Style','text','String','No folder chosen.','Enable','on','FontSize',16);


function [folder_name] = ChooseFolderCallback(eo,ed)
	folder_name = uigetdir(cd,'Choose the folder where the videos are...');
	set(ThisFolder,'String',folder_name);
end


end