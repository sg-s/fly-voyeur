% learnWEParameters
% after tracking is done, it pulls out all putative WE events,
% and asks the user if it is actually a WE and learns how to best tell a
% WE.

%% load data
load M2U00002.MPG.mat
twe=sum(WingExtention');

%% intialise video interface
movie = VideoReader(moviefile)
ff = read(movie,StartTracking);
h =  get(movie,'Height');
w=get(movie,'Width');
mask = squeeze(0*ff(:,:,1));
for i = 1:w
    for j =1:h
        maskthis = 0;
        for k = 1:2
            maskthis = maskthis + ((i-ROIs(1,k))^2 + (j-ROIs(2,k))^2 < ROIs(3,k)^2);
        end
        mask(j,i) = maskthis;
    end
end
%% pick a fly
fly = 4;
otherfly=3;

%% make vectors
flypics = zeros(101,101,twe(fly));
allr(twe(fly)).Centroid = [];
allr(twe(fly)).Area = [];
allr(twe(fly)).MeanIntensity = [];

%% for each putative WE event, load the data
ti=1;
for frame = find(WingExtention(fly,:))
    disp(frame)
    % grab frame
    ff = read(movie,frame);
    ff = (255-ff(:,:,1));
    ff =  imtophat(ff,strel('disk',20)); % remove background
    
    
    
    
    ff = ff.*mask; % mask it
    
    
    % detect objects
    thresh = graythresh(ff);
    rp =[];
    l = logical(im2bw(ff,thresh));
    rp = regionprops(l,'Orientation','Centroid','Area','PixelList');
    
    
     % cut out the fly in question
     cx = round(posx(fly,frame));
     cy = round(posy(fly,frame));
     
     
    % mask the otherfly
    thisfly = ff;
    o_centroids = [];
    for j = 1:length(rp)
        o_centroids=[o_centroids; rp(j).Centroid]; % rearranging all object centroids into a matrix
    end
    temp = [posx(otherfly,frame-1) posy(otherfly,frame-1); o_centroids];


    % find closest object to other fly
    d = squareform(pdist(temp));
    if ~isempty(d)
        d = d(1,2:end);
    end
    [step,otherflyregion] = min(d);
    thisfly(rp(otherflyregion).PixelList(:,2),rp(otherflyregion).PixelList(:,1))=0;

    
    
    thisfly = CutImage(thisfly,[cy cx],50);
    % save this
    flypics(:,:,ti) = thisfly;
    
    % calcualte the metrics for where the wing is
    
    thisfly=imerode(thisfly,strel('disk',2)); % remove legs
    % find orientation of fly
    thisfly2 = thisfly>max(max(thisfly))/2;
    r = regionprops(thisfly2,'Orientation','Centroid','Area');
    r([r.Area]<max([r.Area])/4) = []; % remove small objects
    [~,flybod]=min(sum(abs(vertcat(r.Centroid)-50)'));
    % rotate fly so that is oriented vertically
    thisfly=imrotate(thisfly,90-(r(flybod).Orientation),'crop');
    % remove fly body
    thisfly(thisfly>max(max(thisfly))/2) = 0;
    % remove background noise
    thisfly(thisfly<11) = 0;
    % remove remants of the body
    thisfly = imerode(thisfly,strel('disk',2));
    % find the wing
    r = regionprops(thisfly>5,thisfly,'Centroid','Area','MeanIntensity');
    r([r.Area]<60) = []; % remove small objects 
     for ri = 1:length(r)
        % where is this object?
        if abs(r(ri).Centroid(1)-50) > 15 && abs(r(ri).Centroid(2)-50) < 25 && r(ri).MeanIntensity >15
            allr(ti).Centroid = r(ri).Centroid;
            allr(ti).meanIntensity = r(ri).MeanIntensity;
            allr(ti).Area = r(ri).Area;
        end
    end
            
   ti=ti+1;
   
    
end

