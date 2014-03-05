% SortData.m
% sorts all video files and associated .mat files into folders based on which experiment they are form. this script uses information imported form a EXCEL sheet where the first column is the filename and the seocnd is the genotype it is. 
% make sure you have this excel sheet loaded in matlab and it is called:
Filenamegenotypes

% clean up the database
for i = 1:length(Filenamegenotypes)
	temp = Filenamegenotypes{i,1};
	temp = strrep(temp,char(39),'');	
	Filenamegenotypes{i,1}  = strrep(temp,'/','slash');	

	temp = Filenamegenotypes{i,2};
	temp = strrep(temp,char(39),'');	
	Filenamegenotypes{i,2} =strrep(temp,'/','slash');	
end

allfiles = dir('*.mat');

if exist('Unknown genotype') ~= 7
	mkdir('Unknown genotype')
end

for i = 1:length(allfiles)
	textbar(i,length(allfiles))
	moviefile = strcat(allfiles(i).name(1:end-3),'avi');
	m = find(strcmp(allfiles(i).name, Filenamegenotypes(:,1)));
	if ~isempty(m)
		% there is a match--get genotype
		this_geno = Filenamegenotypes{m,2};
		if exist(this_geno) == 7

		else
			% make the folder and move it
			mkdir(this_geno)
		end
		% move it there
		movefile(allfiles(i).name,strcat(this_geno,'/',allfiles(i).name))
		movefile(moviefile,strcat(this_geno,'/',moviefile))
	else
		% no match, move it to unknown folder
		movefile(allfiles(i).name,strcat('Unknown genotype/',allfiles(i).name))
		movefile(moviefile,strcat('Unknown genotype/',moviefile))

	end
end