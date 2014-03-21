% BatchTask.m
% created by Srinivas Gorur-Shandilya at 15:49 , 19 February 2014. Contact me at http://srinivas.gs/contact/
% splits up a task into as many folders as there are cores on the machine, or as you want.

function [] = BatchTask(n)
if nargin < 1
	n = feature('numCores');
	disp('Splitting task into as many cores as there are on this machine...')
end
allfiles = dir('*.mat'); % run on all *.mat files
% make sure they are real files
badfiles= [];
for i = 1:length(allfiles)
	if strcmp(allfiles(i).name(1),'.')
		badfiles = [badfiles i];
	end
end
allfiles(badfiles) = [];

batch_size = ceil(length(allfiles)/n);

for i = 1:n
	thisfolder=(strcat('batch',mat2str(i)));
	mkdir(thisfolder)
	allfiles = dir('*.mat'); % run on all *.mat files
	% move .mat files in there.

	% make sure they are real files
	badfiles= [];
	for i = 1:length(allfiles)
		if strcmp(allfiles(i).name(1),'.')
			badfiles = [badfiles i];
		end
	end
	allfiles(badfiles) = [];
	
	for j = 1:min([batch_size length(allfiles)])
		
		movefile(allfiles(j).name,strcat(thisfolder,oss,allfiles(j).name))

		% also move the AVI file
		vfile = strcat(allfiles(j).name(1:end-4),'.avi');
		movefile(vfile,strcat(thisfolder,oss,vfile));
	end

end

disp('All done.')

