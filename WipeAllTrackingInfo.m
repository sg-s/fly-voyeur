% WipeAllTrackingInfo.m
% created by Srinivas Gorur-Shandilya at 15:02 , 13 February 2014. Contact me at http://srinivas.gs/contact/
% removes all tracking infromation from the specified .mat files. 
function [] = WipeAllTrackingInfo()
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


for i = 1:length(thesefiles)
	% load the file
	load(thesefiles(i).name)

	% save only the annotation data and overwrite file
	save(thesefiles(i).name,'Channel','DividingLine','LeftStart','ROIs','RightStart','StartTracking','StopTracking','moviefile','n','narenas');


end