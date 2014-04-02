% determines whether the gives structure array with file names of MAT files is raw, partially analysed or fully analysed. 
% 0 -- cannot be determined
% 1 -- raw file
% 2 -- partially tracked
% 3 -- fully tracked
function [state] = DetermineStateOfMATFiles(files)
state = zeros(1,length(files));
for i = 1:length(files)

	% clear all old variables
	posx = [];
    posy = [];
    orientation = [];
    flymissing = [];
    heading = [];
    area=[];
    collision = [];
    adjacency = []; 
    MajorAxis = [];
    MinorAxis = [];
    LookingAtOtherFly = [];
    WingExtention = [];
    SeparationBetweenFlies = [];

	disp('Loading new file....')
    disp(files(i).name)
    warning off
    load(files(i).name)
    warning on
    if nargin < 2
        StartFromHere = [];
    else
        StartFromHere = ForceStartFromHere;
    end
    
    if ~isempty(posx)
        if ~any(isnan(posx(:,StopTracking-1)))
            % fully analysed
            disp('This file looks fully analysed. I will skip this...')
            state(i) = 3;
             
        else
            % not fully analysed. maybe partially analysed?
            % start from where you stopped before
            disp('Partially analysed file; will continue where I left off...')
            StartFromHere= find(isnan(posx(1,:))==0,1,'last');
            disp('...and that is:')
            disp(StartFromHere);
            state(i) = 2;

        end
    else
        % new file.
        disp('This looks like a new file. Will start from the beginning:')
        state(i) = 1;
    end
end
clear i