%% Comparison fo Manual Scoring by Tong-Wey to automated scoring
% In this document, the automated tracking and scoring is compared to a subset of data that was manually scored. Copulation latency and the times of first wing extension are compared here.

%% load TWK's data
load('/code/tracking/TWK_Manual_Scoring.mat')

%% load Track4's outputs

if ~exist('Track4Data')
	cd('/Volumes/500GB TWK/all-videos-analysed/Control/');
	Controls = ComputeCopulationStatistics4(1);

	cd('/Volumes/500GB TWK/all-videos-analysed/C14-1slashD51/');
	dCD = ComputeCopulationStatistics4(1);

	Track4Data = [Controls; dCD];
	clear Controls dCD

end

CopLatencyTrack4 = 0*CopLatency;
WETrack4 = 0*WE;


% compare...
for i = 1:length(Filename)

	% find corresponding data...
	thisline = find(strcmp(Filename{i}, Track4Data(:,1)));
	if ~isempty(thisline)
		if strmatch(Arena(i),'L')
			CopLatencyTrack4(i) = cell2mat(Track4Data(thisline,5));
			WETrack4(i) = cell2mat(Track4Data(thisline,11));
		else
			CopLatencyTrack4(i) = cell2mat(Track4Data(thisline,6));
			WETrack4(i) = cell2mat(Track4Data(thisline,12));
		end
	else
		warning('cannot find file? wtf?')
	end
end

%% Comparison of Copulation Latency
% In this figure, manually scored copulation latency is plotted on the X-axis, and automated scoring is plotted on the Y-axis 
figure('outerposition',[0 0 800 800],'PaperUnits','points','PaperSize',[1200 800]); hold on
scatter(CopLatency,CopLatencyTrack4,502,'.')
copfit = fit(CopLatency,CopLatencyTrack4,'Poly1');
hold on
x = min(CopLatency):1:max(CopLatency);
y =  copfit(x);
plot(x,y,'r','LineWidth',2)
r=rsquare(CopLatency,CopLatencyTrack4);
set(gca,'box','on','FontSize',24,'LineWidth',2)
xlabel('Manual Scoring (s)','FontSize',24)
ylabel('Automated Scoring (s)','FontSize',24)
title('Copulation Latency Comparison')
rtext = strcat('Rsquare of fit is:',oval(r,2)); 
text(100,500,rtext,'FontSize',24)


badfiles = find((abs(WETrack4-WE)>30));
FirstWEbeforeStart = [];
% exclude manual WE detection before start tracking
for i = 1:length(badfiles)
	% find filename
	thisline = find(strcmp(Filename{badfiles(i)}, Track4Data(:,1)));
	% get start tracking
	StartTracking = Track4Data{thisline,17};
	switch Arena{badfiles(i)}
	case 'L'
		if WE(badfiles(i))*30 + Track4Data{thisline,15} < StartTracking
			FirstWEbeforeStart = [FirstWEbeforeStart badfiles(i)];
		end
	case 'R'
		if WE(badfiles(i))*30 + Track4Data{thisline,16} < StartTracking
			FirstWEbeforeStart = [FirstWEbeforeStart badfiles(i)];
		end
	end
end

badfiles = setdiff(badfiles,FirstWEbeforeStart);
afterstart = setdiff(1:length(WE),FirstWEbeforeStart);

% show the filenames and arenas of the badfiles
clc
[Filename(badfiles) Arena(badfiles)]

% show the frames where manual and track 4 says 1st we happened
WEframe = 0*WE;
WETrack4frame = 0*WE;
for i = 1:length(badfiles)
	thisline = find(strcmp(Filename{badfiles(i)}, Track4Data(:,1)));
	switch Arena{badfiles(i)}
	case 'L'
		WEframe(badfiles(i)) = WE(badfiles(i))*30 + Track4Data{thisline,15};
		WETrack4frame(badfiles(i)) = WETrack4(badfiles(i))*30 + Track4Data{thisline,15};
	case 'R'
		WEframe(badfiles(i)) = WE(badfiles(i))*30 + Track4Data{thisline,16};
		WETrack4frame(badfiles(i)) = WETrack4(badfiles(i))*30 + Track4Data{thisline,16};

	end
end

[WEframe(badfiles) WETrack4frame(badfiles)]

% censor extreme cases
WE(WE==600)=0;

figure('outerposition',[0 0 800 800],'PaperUnits','points','PaperSize',[1200 800]); hold on
scatter(WE,WETrack4,502,'.')
copfit = fit(WE,WETrack4,'Poly1');
hold on
x = min(WE):1:max(WE);
y =  copfit(x);
plot(x,y,'r','LineWidth',2)
r=rsquare(WE,WETrack4);
set(gca,'box','on','FontSize',24,'LineWidth',2)
xlabel('Manual Scoring (s)','FontSize',24)
ylabel('Automated Scoring (s)','FontSize',24)
title('First WE Latency Comparison')
rtext = strcat('Rsquare of fit is:',oval(r,2))
text(100,350,rtext,'FontSize',24)