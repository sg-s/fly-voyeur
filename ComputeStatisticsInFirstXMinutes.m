% ComputeStatisticsInFirstXMinutes

X = 180; % seconds after fly introduction

% make sure copulation database is in workspace
if ~exist('MasterCopulationDatabase')
	error('cant find master database')
end

CopulationDatabase = MasterCopulationDatabase;

% now for each file, fill in the appropriate values. 
allfiles = dir('*MPG.mat');
for i = 1:length(allfiles)
	%% core loop
    % load this file
    posx = NaN(1,100000);
    moviefile=[];
    clear StartTracking StopTracking posx posy orientation flymissing WingExtention
    disp(allfiles(i).name)
    load(allfiles(i).name)

    % check file name matches
    databasename = MasterCopulationDatabase{i+1,1};
    databasename = strrep(databasename,char(39),'');
    if ~strmatch(databasename,allfiles(i).name)
    	error('File name wrong')
    end

    % read copulation times 
    copleft = MasterCopulationDatabase{i+1,3};
    copright = MasterCopulationDatabase{i+1,4};

    if copleft > X
    	copleft = X;
    end
    if copright > X
		copright = X;
    end

    % reconstruct copulation times
    CopulationTimes = zeros(1,2);
    CopulationTimes(1) = floor(copleft*30+LeftStart);
    CopulationTimes(2) = floor(copright*30+RightStart);

    % WE
    [FirstWE, TotalWE] = ComputeWEMetrics(WingExtention,CopulationTimes,2,posx,posy,orientation,flymissing);

    % first WE
    CopulationDatabase{i+1,5}=FirstWE(1);
    CopulationDatabase{i+1,6}=FirstWE(2);

    % ratio of WE total time/copulation latency
    CopulationDatabase{i+1,7}=TotalWE(1)/(CopulationTimes(1)-LeftStart(1));
    CopulationDatabase{i+1,8}=TotalWE(2)/(CopulationTimes(2)-RightStart(1));
end