% prun
% run jobs in parallel
function prun(n,algo)
if nargin < 1
	n = feature('numCores');
end
if nargin < 2
	algo = 'GPU';
end


parfor i = 1:n
	cd(strcat('fv_batch',mat2str(i)))
	switch algo
	case 'GPU'
		gpuTrack;
	case 'CPU'
		cpuTrack;
	end
end
delete(gcp)