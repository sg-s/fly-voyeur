% speedchck.m
% compares just regionprops on the whole image to neighbourhood based
% regionprops
%% load
load('temp.mat')
movie = VideoReader('M2U00002.avi');
StartTracking=frame;
%% common operations

    allflies = 1:4;    
        min_area = 400;
jump = 100;
max_area = 1450; 

%% do regionprops on the whole image
tt=    tic;
for frame = StartTracking:StartTracking+30
    ff = read(movie,frame);
    ff = (255-ff(:,:,1)).*mask;
    rp =[];
    l = logical(im2bw(ff,thresh));
    rp = regionprops(l,'Orientation','Centroid','Area');
     % throw out small objects
    badregion = zeros(1,length(rp));
    for j = 1:length(rp)
        if rp(j).Area < min_area
            badregion(j) = 1;
        end
    end
    rp(logical(badregion)) = [];
    
    % assign objects
    % generic case. assigns closest object to last known location
            for i = [allflies(flymissing(:,frame-1)==0) allflies(flymissing(:,frame-1)==1)]  % this prioritises OK flies
                o_centroids = [];
                for j = 1:length(rp)
                    o_centroids=[o_centroids; rp(j).Centroid]; % rearranging all object centroids into a matrix
                end
                temp = [posx(i,frame-1) posy(i,frame-1); o_centroids];

                % figure out if fly is on left or right arena
%                 if posx(i,frame-1) < DividingLine
%                     % on left
%                     temp(temp(:,1) > DividingLine,:) = Inf;
%                 else
%                     temp(temp(:,1) < DividingLine,:) = Inf;
%                 end

                % find closest object to ith fly
                d = squareform(pdist(temp));
                if ~isempty(d)
                    d = d(1,2:end);
                else
                    % something is wrong. skip this frame
                    posx(i,frame) = posx(i,frame-1);
                    posy(i,frame) = posy(i,frame-1);
                    flymissing(i,frame) = 1;
                    return
                end
                [step,thisobj] = min(d);
                if step < jump
                    % assign this object to this fly
                    posx(i,frame) = rp(thisobj).Centroid(1);
                    posy(i,frame) = rp(thisobj).Centroid(2);
                    % mark it as assigned
                    rp(thisobj).Centroid = [Inf Inf];
                elseif isinf(step)
                    % if this is a missing fly, keep going
                    % this means the fly has just gone missing, and other
                    % flies elsewhere in other arenas are segmented
                    posx(i,frame) = posx(i,frame-1);
                    posy(i,frame) = posy(i,frame-1);
                    flymissing(i,frame) = 1;

                else
                    % step exceeds bounds
                    % if this is a missing fly, OK it
                    if flymissing(i,frame-1)
                        % assign this object to this fly
                        posx(i,frame) = rp(thisobj).Centroid(1);
                        posy(i,frame) = rp(thisobj).Centroid(2);
                        % mark it as assigned
                        rp(thisobj).Centroid = [Inf Inf];
                    else
                        % fly goes missing now
                        posx(i,frame) = posx(i,frame-1);
                        posy(i,frame) = posy(i,frame-1);
                        flymissing(i,frame) = 1;

                    end
                end
                
                
    
            end
end
toc(tt)
%% do regionprops on just snippets from the image
tt2=    tic;
n=4;
for frame = StartTracking:StartTracking+30
    ff = read(movie,frame);
    ff = 255-ff(:,:,1).*mask;
    
    % extract neighbourhoods from previous known coordinates
    ns = 50; % neighourhood size
    for i = 1:n
        thisfly = ff(ceil(posy(i,frame-1))-50:ceil(posy(i,frame-1)+50),ceil(posx(i,frame-1)-50):ceil(posx(i,frame-1)+50));
        [x y] = find(thisfly>thresh*255);
        posx(i,frame) = posx(i,frame-1) + mean(y) - 51;
        posy(i,frame) = posy(i,frame-1) + mean(x)- 51;
        
    end
    
    
end
toc(tt2)
