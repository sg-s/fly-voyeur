% determines how long it takes to read 200 frames from a video file
%% choose files to track
allfiles = uigetfile('*','MultiSelect','on'); % makes sure only annotated files are chosen
if ~ischar(allfiles)
% convert this into a useful format
thesefiles = [];
for fi = 1:length(allfiles)
    thesefiles = [thesefiles dir(strcat(source,cell2mat(allfiles(fi))))];
end
else
    thesefiles(1).name = allfiles;
end
for i = 1:length(thesefiles)
    
    % tell the user which movie file this is
    disp(thesefiles(i).name)
    
    
    % configure the movie reader
    movie=VideoReader(thesefiles(i).name);
    
    
    
    % read the first 200 frames
    tic
    for j = 1:200
        ff = read(movie,j);
    end
    toc
    
    % tell the user how long it took
    
end