% ComputeCopulationStatisitcs4.m
% computes copulations tatistics for tracking by track4. 
% created by Srinivas Gorur-Shandilya at 17:48 , 12 November 2013. Contact
% me at http://srinivas.gs/contact/
% this script generates a table with the following information:
% 
% all times in seconds are corrected for when flies are introduced. all frame # are not. 
% all metrics are computed till copulation start. 
% col 1:  filename of video
% col 2:  MD2 hash of the first frame of the video file. 
% col 3:  Copulation Success                                            L 
% col 4:  Copulation Success                                            R 
% col 5:  Copulation Latency (in seconds)                               L
% col 6:  Copulation Latency (in seconds)                               R
% col 7:  Copulation Frame Start                                        L
% col 8:  Copulation Frame Start                                        R
% col 9:  Wing Extension Time/Time Till Copulation                      L
% col 10: Wing Extension Time/Time Till Copulation                      R
% col 11: First Wing Extension (after both flies in, in s)              L
% col 12: First Wing Extension (after both flies in, in s)              R
% col 13: Time Spent Looking at Other Fly/Copulation Time (in s)        L
% col 14: Time Spent Looking at Other Fly/Copulation Time (in s)        R
% col 15: Left Start (frame #)
% col 16: Right Start (frame #)
% col 17: Start Tracking (frame #)
% col 18: Stop Tracking (frame #)
% col 19: Separation between flies/Time till copulation                 L
% col 20: Separation between flies/Time till copulation                 R
% col 21: # of collisions/ cop latency (left)
% col 22: # of collisions/ cop latency (right)
% col 23: total duration of collisions/ cop latency (left)
% col 24: total duration of collisions/ cop latency (right)
% col 25: first looked at other fly                                     L
% col 26: first looked at other fly                                     R
% 
%
% and stores it in a local database in the folder it was run in. It no longer uses the central copulation database. 
function [CopulationDatabase] = ComputeCopulationStatistics4(DryRun,OnlyDoTillXMinutes)

%% some housekeeping and critical options
HashOptions.Method = 'MD2';
if nargin < 1
    DryRun = 1;
end
if nargin < 2
    OnlyDoTillXMinutes = 0;
end

% make sure we are not running in a subfolder
thisfolder = pwd;
ls = regexp(thisfolder,oss);
thisfolder = thisfolder(ls(end)+1:end);
if strcmp(thisfolder,'analysed') || strcmp(thisfolder,'analyse-this') || strcmp(thisfolder,'annotate-this')
    error('Are you sure you want to run here?')
end


%% make sub-directories
if ~DryRun
    if isempty(dir('analyse-this*'))
        mkdir analyse-this
    end
    if isempty(dir('analysed*'))
        mkdir analysed
    end
    if isempty(dir('annotate-this*'))
        mkdir annotate-this
    end
end

%% is there a local database already?
if ~isempty(dir('CopulationDatabase.mat'))
    % already exists. load it
    load CopulationDatabase.mat
else
    CopulationDatabase={'File','Hash','Cop. Success L','Cop. Success R','Cop. Latency L','Cop. Latency R','Cop Frame Start L','Cop Frame Start R','fracWE L','fracWE R','First WE L','First WE R','Looking At Other Fly L','Looking At Other Fly R','Start L','Start R','StartTracking','StopTracking','Mean Separation L','Mean Separation R','# Collisions L','# Collisions R','Coll. Duration L','Coll. Duration R','First Look at Other Fly L','First Look at Other Fly R'};
end

% get all files
allfiles = dir('*MPG.mat');

% remove junk files
badfiles= [];
for i = 1:length(allfiles)
    if strcmp(allfiles(i).name(1),'.')
        badfiles = [badfiles i];
    end
end
allfiles(badfiles) = [];


%% core loop
for i = 1:length(allfiles)
    % load this file
    posx = NaN(1,100000);
    moviefile=[];
    clear StartTracking StopTracking
    disp(allfiles(i).name)
    load(allfiles(i).name)
    
    % is this file analysed?
    if any(isnan((posx(1,StartTracking+7:StopTracking)))) 
        % not analysed. move to analyse-this
        disp('No tracking info. Needs to be tracked. Moving...')
        
        if ~DryRun
            movefile(allfiles(i).name,strcat('analyse-this/',allfiles(i).name))
            movefile(moviefile,strcat('analyse-this/',moviefile))
        end
    else
        % analysed
        % is this file already part of the database?

        movie = VideoReader(moviefile);

        ff = read(movie,1);
        thishash = DataHash(ff,HashOptions);
        
        % look for this hash in the central database
        if any(strcmp(thishash,CopulationDatabase(:,2)))
            % already in database. skip
            disp('Already in database. Moving file to analysed folder...')
            if ~DryRun
                movefile(allfiles(i).name,strcat('analysed/',allfiles(i).name))
                movefile(moviefile,strcat('analysed/',moviefile))
            end
        else
            % new file. not in database
            % check that tracking is OK
            if any(max(posx') -  min(posx') > 400)
                % something wrong
                cprintf('*Red','\nTracking looks wrong. Need to re-annotate and re-track this file. Moving...\n')
                keyboard
                % move to re-analyse
                if ~DryRun
                    movefile(allfiles(i).name,strcat('annotate-this/',allfiles(i).name))
                    movefile(moviefile,strcat('annotate-this/',moviefile))
                end
                
                
            else
            
            
                % 1. find copulation success, latency and frame start
                [CopulationSuccess,CopulationLatency,CopulationStartFrame,nCollisions,CollisionTime] = ComputeCopulationMetrics4(allfiles(i).name);

                % 2. Wing Extension
                cop= [];
                cop.CopulationSuccess = CopulationSuccess;
                cop.CopulationStartFrame = CopulationStartFrame;
                if OnlyDoTillXMinutes
             
                    [FirstWE, TotalWE] = ComputeWEMetrics4(allfiles(i).name,cop,OnlyDoTillXMinutes);
                else
                    [FirstWE, TotalWE] = ComputeWEMetrics4(allfiles(i).name,cop);
                end
                

                if OnlyDoTillXMinutes
                    if CopulationLatency(1) > OnlyDoTillXMinutes*60
                        RealCopStart(1) =  CopulationStartFrame(1);
                        CopulationLatency(1) = OnlyDoTillXMinutes*60;
                        CopulationStartFrame(1) = LeftStart + OnlyDoTillXMinutes*60*30;
                        CopulationSuccess(1) = 0;
                    end
                    if CopulationLatency(2) > OnlyDoTillXMinutes*60
                        RealCopStart(2) =  CopulationStartFrame(2);
                        CopulationLatency(2) = OnlyDoTillXMinutes*60;
                        CopulationStartFrame(2) = LeftStart + OnlyDoTillXMinutes*60*30;
                        CopulationSuccess(2) = 0;
                    end

                    % redo collisions
                    for thisarena = 1:narenas
                        thisfly = thisarena*2-1;
                        otherfly= 2*thisarena;
                        cop = adjacency(thisfly,:)+adjacency(otherfly,:);
                        
                        % correct for mysteriously missing flies
                        cop = cop + max(flymissing((thisfly):otherfly,:));

                        cop(cop>1)=1;

                        % heal breaks and remove flashes
                        cop = filtfilt(ones(1,30)/30,1,cop);
                        cop(cop<0.5)=0;
                        cop(cop>0)=1;

                        [ons,offs]=ComputeOnsOffs(cop);
                        ons(ons>CopulationStartFrame(thisarena)) = [];
                        offs(offs>CopulationStartFrame(thisarena)) = [];
                        nCollisions(thisarena) = length(ons);
                        CollisionTime(thisarena) = (sum(cop(StartTracking:CopulationStartFrame(thisarena))))/(CopulationStartFrame(thisarena)-  StartTracking);
                    end

                end
                


                % add to database
                sz = size(CopulationDatabase);
                addhere = sz(1)+1;

                CopulationDatabase{addhere,1} = allfiles(i).name;
                CopulationDatabase{addhere,2} = thishash;

                try
                    CopulationDatabase{addhere,3} = CopulationSuccess(1);
                    CopulationDatabase{addhere,4} = CopulationSuccess(2);
                end
                CopulationDatabase{addhere,5} = CopulationLatency(1);
                try
                    CopulationDatabase{addhere,6} = CopulationLatency(2);
                end
                CopulationDatabase{addhere,7} = CopulationStartFrame(1);
                try
                    CopulationDatabase{addhere,8} = CopulationStartFrame(2);
                end

                CopulationDatabase{addhere,9} =  TotalWE(1);
                CopulationDatabase{addhere,11} = FirstWE(1);

                try
                    CopulationDatabase{addhere,10} = TotalWE(2);
                    CopulationDatabase{addhere,12} = FirstWE(2);
                end

                l=(LookingAtOtherFly(1,:) + LookingAtOtherFly(2,:));
                l(l>1)=1;
                l =sum(l(StartTracking:CopulationStartFrame(1)))/(CopulationStartFrame(1)-StartTracking);
                CopulationDatabase{addhere,13} = l;


                try
                    l=(LookingAtOtherFly(3,:) + LookingAtOtherFly(4,:));
                    l(l>1)=1;
                    l =sum(l(StartTracking:CopulationStartFrame(2)))/(CopulationStartFrame(2)-StartTracking);
                    CopulationDatabase{addhere,14} = l;
                end

                CopulationDatabase{addhere,15} = LeftStart;
                try
                    CopulationDatabase{addhere,16} = RightStart;
                end
                CopulationDatabase{addhere,17} = StartTracking;
                CopulationDatabase{addhere,18} = StopTracking;

                CopulationDatabase{addhere,19} = sum2(SeparationBetweenFlies(1,StartTracking:CopulationStartFrame(1)))/(CopulationStartFrame(1)-StartTracking);
                try
                    CopulationDatabase{addhere,20} = sum2(SeparationBetweenFlies(2,StartTracking:CopulationStartFrame(2)))/(CopulationStartFrame(2)-StartTracking);
                end

                

                CopulationDatabase{addhere,21} = nCollisions(1);
                CopulationDatabase{addhere,23} = CollisionTime(1);

                try
                    CopulationDatabase{addhere,22} = nCollisions(2);
                    CopulationDatabase{addhere,24} = CollisionTime(2);
                end

                
                t=(LookingAtOtherFly(1,:)+LookingAtOtherFly(2,:)); t(t>1)=1;
                CopulationDatabase{addhere,25} = (find(t,1,'first') - StartTracking)/30;

                try
                    t=(LookingAtOtherFly(3,:)+LookingAtOtherFly(4,:)); t(t>1)=1;
                    CopulationDatabase{addhere,26} = (find(t,1,'first') - StartTracking)/30;
                end


                
                
                % move it
                cprintf('*Green','All OK.\n')
                if ~DryRun
                    movefile(allfiles(i).name,strcat('analysed/',allfiles(i).name))
                    movefile(moviefile,strcat('analysed/',moviefile))
                end
                
                
                
            end
        end
        
        
        
    end
    
    
    
end

if OnlyDoTillXMinutes
    savename = strcat('Results_',mat2str(OnlyDoTillXMinutes),'_minutes_',foldername);
else
    savename = strcat('Results_',foldername);
end

xlwrite(savename,CopulationDatabase)

