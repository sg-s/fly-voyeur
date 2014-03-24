function [] = UnBatch()
batch_folders = dir('*batch*');
rootfolder = cd;
for i = 1:length(batch_folders)
	% move everything here to the root
	cd(batch_folders(i).name)
	try
		movefile('*',rootfolder)
	end
	cd('..')
	try
		rmdir(batch_folders(i).name)
	catch
		
	end
end
clear i

