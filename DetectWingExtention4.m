function [WingExtention,allflylimits] = DetectWingExtention4(theseflies,frame,ROIs,posx,posy,area,WingExtention,flymissing,allflylimits,MajorAxis,MinorAxis,LookingAtOtherFly)
% created by Srinivas Gorur-Shandilya at 9:20 , 18 January 2014. Contact me at http://srinivas.gs/contact/
% DetectWingExtention4 is a rewrite of the wing detection algorithm. it is now heavily reliant on the orientation and the size of the fly reported by AssignObjects4. 

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
            else
                % all OK
                rejectthis = 0;
            end

        end
    end
        

    % finally, see if fly was missing in the past
    if any(flymissing(i,frame-5:frame))
        rejectthis = 1;
        rejectreason  = 3;
    end

    % is fly looking at the other fly? 
    if ~LookingAtOtherFly(i,frame)

            % no, screw this
            rejectthis = 1;
            rejectreason = 7;

    end



    if ~rejectthis
        % extract fly
        thisfly = squeeze(theseflies(i,:,:));

        % flylimits check
        if  max(allflylimits(:,i))==0
            slice = mean(thisfly(:,47:53)');
            flylimits(1) = find(slice>1,1,'first');
            flylimits(2) = flylimits(1) + find(slice(flylimits(1):end)>1,1,'last');
            allflylimits(:,i) = flylimits';

        end

        flylimits = allflylimits(:,i);

        % figure out where you expect to see wings extended
        b=min([15 round(MinorAxis(i,frame)/2)]);
        a =round(diff(flylimits))/2;

        side1 = round(b*1.3);
        side2 = round(b*2.3);
        side3 = round(b*1.6);
        side4 = round(b*2.6);

        % debug
        thisfly2 = thisfly;
        thisfly2(50-round(a/3):55,50-side2:50-side1) = 255;
        thisfly2(50-round(a/3):55,50+side1:50+side2) = 255;
        thisfly2(50-round(3*a/4):45,50-side4:50-side3)=100;
        thisfly2(50-round(3*a/4):45,50+side3:50+side4) = 100;
        imagesc(thisfly2)

        % measure wing asymmetry on back
        leftwing=mean(nonzeros(thisfly(flylimits(1):flylimits(1)+10,45:50)));
        rightwing=mean(nonzeros(thisfly(flylimits(1):flylimits(1)+10,50:55))); 

        % look for wing extension
        try
            leftex1  = sum(nonzeros(thisfly(50-round(a/3):55,50-side2:50-side1)));
            rightex1 = sum(nonzeros(thisfly(50-round(a/3):55,50+side1:50+side2)));

            leftex2  = sum(nonzeros(thisfly(50-round(3*a/4):45,50-side4:50-side3)));
            rightex2 = sum(nonzeros(thisfly(50-round(3*a/4):45,50+side3:50+side4)));

        catch         
            if a < b
                temp=b;
                b = a;
                a = temp; clear temp;
                thisfly=(imrotate(thisfly,90));

                leftex1  = sum(nonzeros(thisfly(50-round(a/3):55,50-side2:50-side1)));
                rightex1 = sum(nonzeros(thisfly(50-round(a/3):55,50+side1:50+side2)));

                leftex2  = sum(nonzeros(thisfly(50-round(3*a/4):45,50-side4:50-side3)));
                rightex2 = sum(nonzeros(thisfly(50-round(3*a/4):45,50+side3:50+side4)));
            else
                disp('WEX 324')
                %keyboard
            end
        end
        
        

        % look for consensus
        if ~any(isnan([rightwing leftwing]))
            WingExtention(i,frame) = (rightex1-leftex1) + (rightex2-leftex2) + (leftwing-rightwing);
        else
            WingExtention(i,frame) = (rightex1-leftex1) + (rightex2-leftex2);
        end
        

    end   
           
end 

