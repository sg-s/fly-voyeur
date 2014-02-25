% created by Srinivas Gorur-Shandilya at 16:03 , 22 February 2014. Contact me at http://srinivas.gs/contact/
% MakeWEValidationReport.m
% generates two figures showing +ve and -ve controls for wing extension. 
function [] = MakeWEValidationReport(filename,WE)

load(filename)

movie = VideoReader(moviefile);

figure('outerposition',[0 0 1200 800],'PaperUnits','points'); hold on

we = abs(WingExtention(1,:)) + abs(WingExtention(2,:));
we(isnan(we))= 0;

theseframes = find(we>max(we)/2);


% do +ve controls first
for i = 1:4
	subplot(2,4,i), hold on
	thisframe = theseframes(randi(length(theseframes)));
	% extract image
	ff = read(movie,thisframe);

	imagesc(ff(:,1:427,:));
	axis image
end


theseframes = find(we==0);
% do -ve controls 
for i = 1:4
	subplot(2,4,i+4), hold on
	thisframe = theseframes(randi(length(theseframes)));
	% extract image
	ff = read(movie,thisframe);

	imagesc(ff(:,1:427,:));
	axis image
end



