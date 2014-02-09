% Find all info from central copulation database that matches files in this folder
% and save it to a new variable
allfiles = dir('*.mat');
LocalData = {};
% load central database
load('/data/copulation/CentralCopulationDatabase.mat')
% grab the first line--headers
LocalData = CentralCopulationDatabase(1,:);

for i = 1:length(allfiles)
	% find where it is in the central database
	ind=find(ismember(CentralCopulationDatabase(:,1),allfiles(i).name));
	if ~isempty(ind)
		LocalData = [LocalData; CentralCopulationDatabase(ind,:)];
	end

end