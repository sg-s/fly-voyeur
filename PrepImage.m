% part of the Track3 codebase
% prepapres a frame for tracking. 
% this function reads a frame from a movie, 
% and subtracts the background. 
% also convoles with a mask. 
% PrepImage also returns ffd, which is the difference between two requested channels
function [ff,ffd] = PrepImage(movie,frame,mask,Channel,ChannelA,ChannelB)
ffd = [];
ff = read(movie,frame);
if nargin > 4
	ffd = ff(:,:,ChannelA) - ff(:,:,ChannelB);
end
ff = (255-ff(:,:,Channel));
ff =  imtophat(ff,strel('disk',20)); % remove background
ff = (ff).*mask; % mask it