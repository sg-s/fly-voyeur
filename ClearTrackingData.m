% ClearTrackingData
% removes trakcing info from files
% 
% 
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function [] = ClearTrackingData()
 
%% choose files to track
allfiles = uigetfile('*.mat','MultiSelect','on'); % makes sure only annotated files are chosen


if exist('allfiles')
    if ischar(allfiles)
        temp = allfiles;
        clear allfiles
        allfiles(1).name = temp;
    elseif iscell(allfiles)
        allfiles=cell2struct(allfiles,'name');
    end
end

% make sure they are real files
badfiles= [];
for i = 1:length(allfiles)
    if strcmp(allfiles(i).name(1),'.')
        badfiles = [badfiles i];
    end
end
clear i
allfiles(badfiles) = [];
thesefiles = allfiles;
clear allfiles

for i = 1:length(thesefiles)
	load(thesefiles(i).name)
		save(thesefiles(i).name,'DividingLine','n','StartTracking','StopTracking','LeftStart','RightStart','narenas','moviefile','ROIs','Channel');

end