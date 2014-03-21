% SpawnBatchWorkers.m
% spawns as many batch workers as there are CPU cores on the machine and gets them working on all the batches. 


load batch_task
cd(data_here)
batches = dir(data_here);
removethese=[];
for i = 1:length(batches)
	if isempty(strfind(batches(i).name,'fv_batch'))
		removethese = [removethese i];
	end
end
batches(removethese)=[];

pause(rand*10)

% Seize one and run it 
newname = strcat('running_',RandomString(4));
movefile(batches(1).name,newname);
cd(newname)
cpuTrack(-1);