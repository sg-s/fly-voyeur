% ComputeWEMetrics.m
% created by Srinivas Gorur-Shandilya at 18:34 , 12 November 2013. Contact
% me at http://srinivas.gs/contact/
function [FirstWE, TotalWE] = ComputeWEMetrics(WingExtention,CopulationTimes,narenas,posx,posy,orientation,flymissing)
% debug
owe = WingExtention; % original data

% create data structures
FirstWE = zeros(1,narenas);
TotalWE = zeros(1,narenas);

% remove all WE within 5 frames of the fly going missing. 
for i = 1:4
    wee =  find(WingExtention(i,:));
    for j = wee
        fm = max(flymissing(i,j-5:j+5));
        if fm
            WingExtention(i,j) = 0;
        end
    end
end


% convolve the train of WE with a gaussian to remove breaks
sigma = 5; % frames
size = 30;
x = linspace(-size / 2, size / 2, size);
gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
gaussFilter = gaussFilter / sum (gaussFilter); % normalize
for i = 1:4
    temp = conv (WingExtention(i,:), gaussFilter, 'same');
    temp(temp<0.5) = 0;
    temp(temp>0) = 1;
    WingExtention(i,:) =temp;
end


% remove all WE after Copulation Start
for i = 1:narenas
    if CopulationTimes(i) > 0
        thisfly = 2*i;
        otherfly = 2*i-1;

        WingExtention(thisfly,CopulationTimes(i):end) = 0;
        WingExtention(otherfly,CopulationTimes(i):end) = 0;
    end
end

% remove all WE when flies are further than 100px apart
for i = 1:narenas
    thisfly = 2*i;
    otherfly = 2*i-1;
    d = sqrt((posx(thisfly,:)-posx(otherfly,:)).^2 + (posy(thisfly,:)-posy(otherfly,:)).^2);
    d(d>100)=0;
    d(d>0)= 1;
    WingExtention(thisfly,d==0) = 0;
    WingExtention(otherfly,d==0) = 0;
    
    % remove all We when the flies when the WE fly is not looking at the other
    % fly
    % calcualte angle between flies
    wee = find(WingExtention(thisfly,:));
    
    for j = wee
        anglebwflies=atand((posx(thisfly,j)-posx(otherfly,j))/(posy(thisfly,j)-posy(otherfly,j)));
        ad = AngularDifference(anglebwflies,orientation(thisfly,j));
        if abs(ad) > 60
            WingExtention(thisfly,j) = 0;
        else
            
        end
    end
   

    wee = find(WingExtention(otherfly,:));
    for j = wee

        anglebwflies=atand((posx(thisfly,j)-posx(otherfly,j))/(posy(thisfly,j)-posy(otherfly,j)));
        ad = AngularDifference(anglebwflies,orientation(otherfly,j));
        if abs(ad) > 60
            WingExtention(otherfly,j) = 0;
        else
            
        end
    end
    

end
  

% finally, the tracks of the two flies can get mixed up. so let's just pool
% them
temp = WingExtention(1,:) + WingExtention(2,:);
temp(temp>1)=1;
WingExtention(1,:)  = temp;
WingExtention(2,:) = temp;

temp = WingExtention(3,:) + WingExtention(4,:);
temp(temp>1)=1;
WingExtention(3,:)  = temp;
WingExtention(4,:) = temp;


% find first WE
if ~isempty(find(WingExtention(1,:)))
    FirstWE(1)=find(WingExtention(1,:),1,'first');
else
    if CopulationTimes(1) > 0
        disp('Copulation but no WE?')
        keyboard
    end
    FirstWE(1) = Inf;
end
if ~isempty(find(WingExtention(3,:)))
    FirstWE(2)=find(WingExtention(3,:),1,'first');
else
    if CopulationTimes(2) > 0
        disp('Copulation but no WE?')
        keyboard
    end
    FirstWE(2) = Inf;
end

% find total WE
TotalWE(1)=sum(WingExtention(1,:));
TotalWE(2)=sum(WingExtention(3,:));

    

%% legacy code

%% post-process
% for i = 1:narenas
%     % remove all WE when flies are closer than 50px
%     thisfly = 2*i;
%     otherfly = 2*i-1;
%     d=((posx(thisfly,:)-posx(otherfly,:)).^2) + ((posy(thisfly,:)-posy(otherfly,:)).^2);
%     d =sqrt(d);
%     WingExtention(thisfly,d<50) = 0;
%     WingExtention(otherfly,d<50) = 0;
%     
%     % figure out which arena (which ROI)
%     [~,thisarena]=min(abs(mean(posx(thisfly,StartTracking:StopTracking)) - ROIs(1,:)));
%     
%     % remove all WE when the fly is close to the edge.
%     d=((posx(thisfly,:)-ROIs(1,thisarena)).^2) + ((posy(thisfly,:)-ROIs(2,thisarena)).^2);
%     d=sqrt(d);
%     WingExtention(thisfly,d>ROIs(3,thisarena)-10) = 0; 
%     
%     
%     % remove all WE when the fly is close to the edge.
%     d=((posx(otherfly,:)-ROIs(1,thisarena)).^2) + ((posy(otherfly,:)-ROIs(2,thisarena)).^2);
%     d=sqrt(d);
%     WingExtention(otherfly,d>ROIs(3,thisarena)-10) = 0; 
%     
% end