% ComputeCopulationStatisitcs.m
% created by Srinivas Gorur-Shandilya at 17:48 , 12 November 2013. Contact
% me at http://srinivas.gs/contact/
% this script generates a table with the following information:
% 
% col 1: filename of video
% col 2: MD2 hash of the first frame of the video file.
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
%
% for all the files in the folder it is run in. 
% this script maintains a central database on
% /data/copulation/CentralCopulationDatabase.mat
% and adds to it if it thinks it is a new file. 

%% some housekeeping
HashOptions.Method = 'MD2';


%% load the central database
load('/data/copulation/CentralCopulationDatabase.mat')

%% get a list of all files here
allfiles = dir('*.mat');

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

%% core loop
for i = 1:length(allfiles)
    % load this file
    posx = NaN(1,100000);
    moviefile=[];
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
        if any(strcmp(thishash,CentralCopulationDatabase(:,2)))
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
                [CopulationTimes] = ComputeCopulationMetrics(adjacency,2);
                



                % 2. find first wing extension
                % 3. find ration of WE/copulation latency
                [FirstWE, TotalWE] = ComputeWEMetrics(WingExtention,CopulationTimes,2,posx,posy,orientation,flymissing);
                
                % add to database
                sz = size(CentralCopulationDatabase);
                addhere = sz(1)+1;
                CentralCopulationDatabase{addhere,11} = CopulationTimes(1)>0;
                CentralCopulationDatabase{addhere,12} = CopulationTimes(2)>0;
                
                
                CopulationTimes(CopulationTimes==0) = StopTracking; % flies that never copulate
                % convert frame number to actual latency
                CopulationLatency = (CopulationTimes-[LeftStart RightStart])/30;

                

                % add the name
                CentralCopulationDatabase{addhere,1}=allfiles(i).name;

                % add the hash
                CentralCopulationDatabase{addhere,2}=thishash;

                % cop latency
                CentralCopulationDatabase{addhere,3}=CopulationLatency(1);
                CentralCopulationDatabase{addhere,4}=CopulationLatency(2);

                % first WE
                CentralCopulationDatabase{addhere,5}=FirstWE(1);
                CentralCopulationDatabase{addhere,6}=FirstWE(2);

                % ratio of WE total time/copulation latency
                CentralCopulationDatabase{addhere,7}=TotalWE(1)/(CopulationTimes(1)-LeftStart(1));
                CentralCopulationDatabase{addhere,8}=TotalWE(2)/(CopulationTimes(2)-RightStart(1));

                % frame where copulation starts
                CentralCopulationDatabase{addhere,9}=CopulationTimes(1);
                CentralCopulationDatabase{addhere,10}=CopulationTimes(2);


                % save it
                save('/data/copulation/CentralCopulationDatabase.mat','CentralCopulationDatabase')
                
                % move it
                disp('All OK. Moving file to anlysed folder...')
                movefile(allfiles(i).name,strcat('analysed/',allfiles(i).name))
                movefile(moviefile,strcat('analysed/',moviefile))
                
                
                
            end
        end
        
        
        
    end
    
    
    
end
