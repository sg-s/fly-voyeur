% BatchTask.m
% created by Srinivas Gorur-Shandilya at 15:49 , 19 February 2014. Contact me at http://srinivas.gs/contact/
% splits up a task into as many folders as there are cores on the machine, or as you want.

function [] = BatchVideotask(n,mext)


allfiles = dir(strcat('*',mext)); % run on all movie files
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
	thisfolder=(strcat('fv_batch',mat2str(i)));
	mkdir(thisfolder)
	allfiles = dir(strcat('*',mext)); % run on all movie files
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

	end

end

disp('All done.')

% save where this is 
temp=mfilename('fullpath');
s=strfind(temp,'/');
temp = temp(1:s(end));
filename = strcat(temp,'batch_task.mat');
data_here = cd;
save(filename,'data_here')



