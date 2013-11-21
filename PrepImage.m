% part of the Track3 codebase
% prepapres a frame for tracking. 
% this function reads a frame from a movie, 
% and subtracts the background. 
% also convoles with a mask. 
function [ff] = PrepImage(movie,frame,mask)

ff = read(movie,frame);
ff = (255-ff(:,:,1));
ff =  imtophat(ff,strel('disk',20)); % remove background
ff = ff.*mask; % mask it