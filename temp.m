root = ('/Volumes/500GB TWK/all-videos-analysed/');

allfolders = dir(root);

for i = 1:length(allfolders)
	if isempty(strfind(allfolders(i).name,'.'))
		cd(strcat(root,allfolders(i).name))
		ComputeCopulationStatistics4(1)
		if ~isempty(strfind(allfolders(i).name,'TRP')) || ~isempty(strfind(allfolders(i).name,'52c'))
			ComputeCopulationStatistics4(1,4)
		end
	end

end