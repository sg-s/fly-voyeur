% ComputeCopulationStatisitcs.m
% created by Srinivas Gorur-Shandilya at 17:48 , 12 November 2013. Contact
% me at http://srinivas.gs/contact/
% this script generates a table with the following information:
% 
% col 1: filename of video
% col 2: MD2 hash of the first frame of the video file. This is a unique number for each video file
% col 3: Copulation latency, Left (in s, corrected for when flies introduced)
% col 4: Copulation latency, Right (in s, corrected...)
% col 5: 1st Wing Ex., Left (frame #)
% col 6: 1st Wing Ex., right (frame #)
% col 7: (Total Duration of WE)/(Total Time till copulation) LEFT
% col 8: (Total Duration of WE)/(Total Time till copulation) RIGHT
% col 9: frame # where copulation starts LEFT
% col 10: frame # where copulation starts RIGHT
% col 11: successful copulation: 1/0 true/false Left
% col 12: successful copulation: 1/0 true/false Right
% col 13: start tracking (frame #)
% col 14: stop tracking (frame #)
% col 15: Left Start (frame #)
% col 16: Right Start (frame #)
% col 17: empty
% col 18: empty
% col 19: mean distance b/w male and female/ cop latency in seconds (left)
% col 20: mean distance b/w male and female/ cop latency in seconds (right)
% col 21: # of collisions/ cop latency (left)
% col 22: # of collisions/ cop latency (right)
% col 23: total duration of collisions/ cop latency (left)
% col 24: total duration of collisions/ cop latency (right)
% 
%
% and stores it in a local database in the folder it was run in. It no longer uses the central copulation database. 

%% some housekeeping
HashOptions.Method = 'MD2';

% make sure we are not running in a subfolder
thisfolder = pwd;
ls = regexp(thisfolder,'/');
thisfolder = thisfolder(ls(end)+1:end);
if strcmp(thisfolder,'analysed') || strcmp(thisfolder,'analyse-this') || strcmp(thisfolder,'annotate-this')
    error('Are you sure you want to run here?')
end


%% make sub-directories
if isempty(dir('analyse-this*'))
    mkdir analyse-this
end
if isempty(dir('analysed*'))
    mkdir analysed
end
if isempty(dir('annotate-this*'))
    mkdir annotate-this
end

%% is there a local database already?
if ~isempty(dir('CopulationDatabase.mat'))
    % already exists. load it
    load CopulationDatabase.mat
else
    CopulationDatabase={'File','Hash','Cop. Left','Cop. Right','WE. Left','WE. Right','fWE. Left','fWE. Right','Cop Start L','Cop Start R','Success L','Success R','StartTracking','StopTracking','Start L','Start R','','','Mean Separation L','Mean Separation R','# Collisions L','# Collisions R','Coll. Duration L','Coll. Duration R'};
end

% get all files
allfiles = dir('*MPG.mat');

%% core loop
for i = 1:length(allfiles)
    % load this file
    posx = NaN(1,100000);
    moviefile=[];
    clear StartTracking StopTracking
    disp(allfiles(i).name)
    load(allfiles(i).name)
    
    % is this file analysed?
    if any(isnan((posx(1,StartTracking:StopTracking)))) 
        % not analysed. move to analyse-this
        disp('No tracking info. Needs to be tracked. Moving...')
        movefile(allfiles(i).name,strcat('analyse-this/',allfiles(i).name))
        movefile(moviefile,strcat('analyse-this/',moviefile))
    else
        % analysed
        % is this file already part of the database

        movie = VideoReader(moviefile);

        ff = read(movie,1);
        thishash = DataHash(ff,HashOptions);
        
        % look for this hash in the central database
        if any(strcmp(thishash,CopulationDatabase(:,2)))
            % already in database. skip
            disp('Already in database. Moving file to analysed folder...')
            movefile(allfiles(i).name,strcat('analysed/',allfiles(i).name))
            movefile(moviefile,strcat('analysed/',moviefile))
        else
            % new file. not in database
            % check that tracking is OK
            if any(max(posx') -  min(posx') > 300)
                % something wrong
                disp('Tracking looks wrong. Need to re-annotate and re-track this file. Moving...')
                % move to re-analyse
                movefile(allfiles(i).name,strcat('annotate-this/',allfiles(i).name))
                movefile(moviefile,strcat('annotate-this/',moviefile))
                
                
            else
            
            
                % 1. find copulation latency
                [CopulationTimes] = ComputeCopulationMetrics(adjacency,2,flymissing,allfiles(i).name);
                
                % coplat = (CopulationTimes - [LeftStart RightStart])/30; % in seconds

                % CopulationTimes(coplat>360) = 360*30; % 4 min

                

                % 2. find first wing extension
                % 3. find ration of WE/copulation latency
                [FirstWE, TotalWE] = ComputeWEMetrics(WingExtention,CopulationTimes,2,posx,posy,orientation,flymissing);
                
                % add to database
                sz = size(CopulationDatabase);
                addhere = sz(1)+1;
                if CopulationTimes(1)>0
                    CopulationDatabase{addhere,11} = 1;
                else
                    CopulationDatabase{addhere,11} = 0;
                end
                if CopulationTimes(2)>0
                    CopulationDatabase{addhere,12} = 1;
                else
                    CopulationDatabase{addhere,12} = 0;
                end
                
                
                
                CopulationTimes(CopulationTimes==0) = StopTracking; % flies that never copulate
                % convert frame number to actual latency
                CopulationLatency = (CopulationTimes-[LeftStart RightStart])/30;

                

                % add the name
                CopulationDatabase{addhere,1}=allfiles(i).name;

                % add the hash
                CopulationDatabase{addhere,2}=thishash;

                % cop latency
                CopulationDatabase{addhere,3}=CopulationLatency(1);
                CopulationDatabase{addhere,4}=CopulationLatency(2);

                % first WE
                CopulationDatabase{addhere,5}=FirstWE(1);
                CopulationDatabase{addhere,6}=FirstWE(2);

                % ratio of WE total time/copulation latency
                CopulationDatabase{addhere,7}=TotalWE(1)/(CopulationTimes(1)-LeftStart(1));
                CopulationDatabase{addhere,8}=TotalWE(2)/(CopulationTimes(2)-RightStart(1));

                % frame where copulation starts
                CopulationDatabase{addhere,9}=CopulationTimes(1);
                CopulationDatabase{addhere,10}=CopulationTimes(2);

                % other info
                CopulationDatabase{addhere,13}=StartTracking;
                CopulationDatabase{addhere,14}=StopTracking;
                CopulationDatabase{addhere,15}=LeftStart;
                CopulationDatabase{addhere,16}=RightStart;

                % mean separation between male and female
                if CopulationTimes(1) == 0
                    % no cop
                    temp=sqrt(sum((posx(1,StartTracking:StopTracking)-posx(2,StartTracking:StopTracking)).^2 + (posy(1,StartTracking:StopTracking)-posy(2,StartTracking:StopTracking)).^2))/(StopTracking-LeftStart);
                    CopulationDatabase{addhere,19} = temp/30;

                else
                    CopulationDatabase{addhere,19}=sqrt(sum((posx(1,StartTracking:CopulationLatency(1)*30)-posx(2,StartTracking:CopulationLatency(1)*30)).^2 + (posy(1,StartTracking:CopulationLatency(1)*30)-posy(2,StartTracking:CopulationLatency(1)*30)).^2))/(CopulationLatency(1));
                 
                end

                if CopulationTimes(2) == 0
                    % no cop
                    temp=sqrt(sum((posx(3,StartTracking:StopTracking)-posx(4,StartTracking:StopTracking)).^2 + (posy(3,StartTracking:StopTracking)-posy(4,StartTracking:StopTracking)).^2))/(StopTracking-RightStart);
                    CopulationDatabase{addhere,20} = temp/30;

                else
                    CopulationDatabase{addhere,20}=sqrt(sum((posx(3,StartTracking:CopulationLatency(2)*30)-posx(4,StartTracking:CopulationLatency(2)*30)).^2 + (posy(3,StartTracking:CopulationLatency(2)*30)-posy(4,StartTracking:CopulationLatency(2)*30)).^2))/(CopulationLatency(2));
                 
                end

                % now calculate frequency and duration of collisions till copulation. 
                if CopulationTimes(1) == 0
                    ncoll = adjacency(1,StartTracking:StopTracking)+adjacency(2,StartTracking:StopTracking);
                    ncoll(ncoll>1) = 1;
                    fcoll = diff(ncoll);
                    fcoll(fcoll<0) = 0;
                    fcoll = sum(fcoll)/(CopulationLatency(1));
                    ncoll = sum(ncoll)/(CopulationLatency(1)*30);
                else
                    ncoll = adjacency(1,StartTracking:CopulationTimes(1))+adjacency(2,StartTracking:CopulationTimes(1));
                    ncoll(ncoll>1) = 1;
                    fcoll = diff(ncoll);
                    fcoll(fcoll<0) = 0;
                    fcoll = sum(fcoll)/(CopulationLatency(1));
                    ncoll = sum(ncoll)/(CopulationLatency(1)*30);
                end
                CopulationDatabase{addhere,21} = fcoll;
                CopulationDatabase{addhere,23} = ncoll;

                if CopulationTimes(2) == 0
                    ncoll = adjacency(3,StartTracking:StopTracking)+adjacency(4,StartTracking:StopTracking);
                    ncoll(ncoll>1) = 1;
                    fcoll = diff(fcoll);
                    fcoll(fcoll<0) = 0;
                    fcoll = sum(fcoll)/(CopulationLatency(2));
                    ncoll = sum(ncoll)/(CopulationLatency(2)*30);
                else
                    ncoll = adjacency(3,StartTracking:CopulationTimes(2))+adjacency(4,StartTracking:CopulationTimes(2));
                    ncoll(ncoll>1) = 1;
                    fcoll = diff(ncoll);
                    fcoll(fcoll<0) = 0;
                    fcoll = sum(fcoll)/(CopulationLatency(2));
                    ncoll = sum(ncoll)/(CopulationLatency(2)*30);
                end
                CopulationDatabase{addhere,22} = fcoll;
                CopulationDatabase{addhere,24} = ncoll;






                % save it
                save('/data/copulation/CopulationDatabase.mat','CopulationDatabase')
                
                % move it
                disp('All OK. Moving file to analysed folder...')
                movefile(allfiles(i).name,strcat('analysed/',allfiles(i).name))
                movefile(moviefile,strcat('analysed/',moviefile))
                
                
                
            end
        end
        
        
        
    end
    
    
    
end
