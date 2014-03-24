% prun
% run jobs in parallel
n = feature('numCores');
parfor i = 1:n
	cd(strcat('fv_batch',mat2str(i)))
	gpuTrack(-1);
end
delete(gcp)