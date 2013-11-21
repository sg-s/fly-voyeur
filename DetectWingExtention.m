function [WingExtention] = DetectWingExtention(ff,frame,ROIs,posx,posy,area,rp,WingExtention,orientation,flymissing)
% this function detects Wing Extension events. 
% this is how the alogirthm works:
% 
% the following conditions have to be met:
% 1. is the fly visible?
% 2. is is the other fly visible?
% 3. are they sufficently close? (define a distance)
% 4. are the fly's wing extension regions clear of the edge? 
% 5. are the fly's wing extension regions clear fo the other fly?

% if all these conditions are met, 

% - extract the fly image. 
% - threshold the image, only pixels above 1/2 the brightest pixels
% - find the orientation of the fly
% - rotate the fly to orient it vertically 
% - remove the legs by eroding the image with a 2 disc
% - remove the body by removing all bright pixels
% - compare pixel intensities of the right to the left. 
n = size(posx,1);
for i = 1:n
    % set rejectthis variable.
    rejectthis = 1; % automatically assume that we won't look at this fly
    rejectreason=0;
    if ~flymissing(i,frame)  % ------------------------------- step 1 passed
        cx = round(posx(i,frame));
        cy = round(posy(i,frame));
        % are both flies visible?
        switch mod(i,2)
            case 1
                otherfly=i+1;
            case 0
                otherfly=i-1;
        end
        if flymissing(otherfly,frame)
            % reject
            rejectreason = 1;
        else % ------------------------------------------------ step 2 passed
            % are the two flies very far apart?
            if  pdist2([posx(i,frame),posy(i,frame)],[posx(otherfly,frame),posy(otherfly,frame)])>200
                % reject
                rejectreason = 2;
            else % ------------------------------------------------ step 3 passed
                % extract fly
                thisfly = CutImage(ff,[cy cx],50);

                % find points orthogonal to body axis,around 27 pixels off
                [left,right,leftw,rightw] = ExtractWingPixelValues(thisfly,orientation(i,frame));
                left(1) = posx(i,frame)+left(1)-50;
                left(2) = posy(i,frame)+left(2)-50;
                right(1) = posx(i,frame)+right(1)-50;
                right(2) = posy(i,frame)+right(2)-50;
                % are flies wing locations clear of edge
                temp= abs(pdist2([left;right],ROIs([1 2],:)')-mean(ROIs(3,:))); % radial distances to circle edge

                if max(max(temp))<15
                    % fail. reject.
                     rejectreason = 3;
                else
                    % ------------------------------------------------ step 4 passed
                    % are flies wing locations clear of other fly?
                    temp=pdist2([left;right],[posx(:,frame),posy(:,frame)]);
                    temp(temp<26) = []; % remove reference to this fly
                    if any(temp<30)
                        % fail. reject.
                        rejectreason = 4;
                    else
                        % ------------------------------------------------ step 5 passed
                        % all OK!
                        rejectthis = 0;
                    end
                end 

            end

        end


        % remove other fly
        thisfly = ff;
        otherflyregion=find(area(otherfly,frame)==[rp.Area]);
        if isempty(otherflyregion)
                % cant find other fly propeorly
                rejectreason=9;
                rejectthis=1;
        elseif length(otherflyregion) > 1
            % probably colliding flies, that have been seoerated
            % forecefully by k-means
            % try to find the other fly anyway
            if any((orientation(otherfly,frame) - [rp.Orientation]) == 0)
                otherflyregion = find((orientation(otherfly,frame) - [rp.Orientation]) == 0);
            elseif any((orientation(otherfly,frame) + [rp.Orientation]) == 0)
                otherflyregion = find((orientation(otherfly,frame) + [rp.Orientation]) == 0);
            end
            if length(otherflyregion) > 1 
                rejectthis = 1;
                rejecttreason = 13;
            end

        end

        % findally, see if fly was missing in the past
        if any(flymissing(i,frame-5:frame))
            rejectthis = 1;
            rejectreason  =11;
        end

        

        if ~rejectthis
            % we will consider this for wing extention

             thisfly(rp(otherflyregion).PixelList(:,2),rp(otherflyregion).PixelList(:,1))=0;



            thisfly = CutImage(thisfly,[cy cx],50);
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

            % just remove all the middle
            thisfly(:,40:60) = 0;

            % find the wing
            r = regionprops(thisfly>5,thisfly,'Centroid','Area','MeanIntensity');
            r([r.Area]<60) = []; % remove small objects 
            if ~isempty(r)
                if length(r) == 1
                    if (abs(r.Centroid(1)-50) > 15) && (abs(r.Centroid(1)-50) < 40) && abs(r.Centroid(2)-50) < 10 && r.MeanIntensity > 15
                        % far away from midline horizontally, but
                        % close to midline vertically.
                        WingExtention(i,frame) = 1;  


                    end
                else
                    % reject.
                end

            end
        end

    end            
end 

