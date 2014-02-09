function [WingExtention] = DetectWingExtention3(theseflies,frame,ROIs,posx,posy,area,WingExtention,flymissing,allflylimits)
% created by Srinivas Gorur-Shandilya at 9:20 , 18 January 2014. Contact me at http://srinivas.gs/contact/
% DetectWingExtention3 is a rewrite of DetectWingExtention2 using a new algorithm. 
% 
% the following conditions have to be met:
% 1. is the fly visible?
% 2. is is the other fly visible?
% 3. are they sufficently close? (define a distance)
% 4. are the fly's wing extension regions clear of the edge? 
% 5. are the fly's wing extension regions clear of the other fly?

% if all these conditions are met, 

% - extract the fly image. 
% - threshold the image, only pixels above 1/2 the brightest pixels
% - find the orientation of the fly
% - rotate the fly to orient it vertically 
% - remove the legs by eroding the image with a 2 disc
% - remove the body by removing all bright pixels
% - compare pixel intensities of the right to the left. 
% 
% WingExtention2 differs from the first version in that other flies are deleted explicitly, pixel for pixel, and this works for 3 flies. 
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
                thisfly = squeeze(theseflies(i,:,:));

                % find points orthogonal to body axis,around 27 pixels off
                [left,right,leftw,rightw] = ExtractWingPixelValues(thisfly,90);
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

        

        % finally, see if fly was missing in the past
        if any(flymissing(i,frame-5:frame))
            rejectthis = 1;
            rejectreason  =11;
        end


        if ~rejectthis
            % extract fly
            thisfly = squeeze(theseflies(i,:,:));
            flylimits = allflylimits(:,i);

            % measure wing asymmetry on back

            leftwing=mean(nonzeros(thisfly(flylimits(1):flylimits(1)+10,45:50)));
            rightwing=mean(nonzeros(thisfly(flylimits(1):flylimits(1)+10,50:55))); 

            % remove fly body and other noise
            wingpx = max([leftwing rightwing]);
            thisfly(thisfly>(wingpx+255)/2) = 0;
            thisfly(thisfly<wingpx/2) = 0;

            % remove legs and remnants of fly
            thisfly = imerode(thisfly,strel('disk',1));

            % look for wing extension
            leftex1 =  sum(nonzeros(thisfly(40:55,25:30)));
            rightex1 =  sum(nonzeros(thisfly(40:55,70:75)));

            leftex2 =  sum(nonzeros(thisfly(30:45,25:35)));
            rightex2 =  sum(nonzeros(thisfly(30:45,60:70)));

            

            if max([rightex1 leftex1]) == 0
                % no WE
            elseif rightex1/rightwing > 10
                WingExtention(i,frame) = 2;
            elseif leftex1/leftwing > 10
                WingExtention(i,frame) = 1;
            elseif rightex2/rightwing > 10
                WingExtention(i,frame) = 2;
            elseif leftex2/leftwing > 10
                WingExtention(i,frame) = 1;
                
            end

        end



    end            
end 

