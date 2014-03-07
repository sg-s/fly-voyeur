function [orientation,heading,theseflies,allflylimits] = gpuFindHeadingsAndFixOrientations(frame,StartTracking,rp,posx,posy,orientation,heading,flymissing,ff,allflylimits,MajorAxis,MinorAxis,LookingAtOtherFly,WingExtention,SeparationBetweenFlies)

n  =size(posx,1);
%% some final computations
theseflies = (zeros(n,101,101)); % cut out images of flies

debugstatus = 0;

for i = 1:n
    switch i 
        case 1
            otherfly= 2;
            arena=1;
        case 2
            otherfly= 1;
            arena=1;
        case 3
            otherfly= 4;
            arena=2;
        case 4
            otherfly= 3;
            arena=2;
    end

    if debugstatus
        disp(i)
    end

    % and make sure orientations are OK
    if (orientation(i,frame)) > 180
        orientation(i,frame) =  orientation(i,frame) - 360;
    elseif  (orientation(i,frame)) < -180
        orientation(i,frame) =  orientation(i,frame) + 360;
    end


    flip = 1; 
    % build a headings matrix
    if frame - StartTracking > 6
        hh = [posx(i,frame)-posx(i,frame-5) posy(i,frame)-posy(i,frame-5)];                   
    else
         hh = [posx(i,frame)-posx(i,frame-1) posy(i,frame)-posy(i,frame-1)];
    end
    if hh(1) < 0
        heading(i,frame)=180+atand(hh(2)/hh(1));
    else
        heading(i,frame)=atand(hh(2)/hh(1));
    end
    if heading(i,frame) < 0
        heading(i,frame) = 360+heading(i,frame);

    end

    % if orientation flips, flip it back. but this is overridden by wing-based orientation
    if AngularDifference(orientation(i,frame),orientation(i,frame-1)) > 120
        if debugstatus
            disp('flipping orientation because it flipped from last frame')
        end
        orientation(i,frame) = FlipOrientation(orientation(i,frame));
    end


    % extract individual fly images
    if ~flymissing(i,frame) 
        thisfly = RemoveAllOtherFlies(ff,posx(i,frame),posy(i,frame),rp);
        cx = round(posx(i,frame));
        cy = round(posy(i,frame));
        thisfly = (CutImage(thisfly,[cy cx],50));

        % adjust contrast
        thisfly = gpuArray(imadjust(thisfly));

        % rotate fly so that is oriented vertically
        thisfly=(imrotate(thisfly,270+(orientation(i,frame)),'crop'));


        % remove junk
        thisfly = gather(imerode(thisfly,strel('disk',2)));

        % delete background
        thisfly(thisfly<50)=0; % hard-coded parameters are fine because we are using imadjust, which forces the image from 0 to 255

        % Only do so if the fly is not missing, and is sufficiently far away from the other fly
        fs = FlySeperation(i,otherfly,posx(:,frame),posy(:,frame),MajorAxis(:,frame),MinorAxis(:,frame),orientation(:,frame));
        if length(rp)==n &&  fs > 20

            if debugstatus
                disp('OK, i am going to try to do wing-based orientation detection')
            end

            % check orientation OK
            slice = mean(thisfly(:,47:53)');
            
            if max(slice([1:10, 90:101])) > 0
                slice(1:10) = 0; slice(90:101) = 0;
            end
            flylimits(1) = find(slice(1:50)==0,1,'last'); % this should be the tail
            flylimits(2) = 50+find(slice(51:end)==0,1,'first'); % this should be the head


            if max(allflylimits(:,i)) == 0
                allflylimits(:,i) = flylimits';
            end
            
            mptail = mean(nonzeros(thisfly(flylimits(1):flylimits(1)+10,45:55))); 
            mphead = mean(nonzeros(thisfly(flylimits(2)-10:flylimits(2),45:55))); % head

            % check if there is a significant difference between them
            if abs(mptail-mphead) > 20
                if mptail < mphead
                    % good, head brighter than tail
                    
                else
                    % orientation is 180° off
                    
                    orientation(i,frame) = FlipOrientation(orientation(i,frame));
                    thisfly= flipud(thisfly);
                    flip = -1*flip;
                end
            else
                if debugstatus
                    disp('cant tell which is tail and which is head')
                end
            end


        end
        
        theseflies(i,:,:) = thisfly;
    end




    % and make sure orientations are OK
    if (orientation(i,frame)) > 180
        orientation(i,frame) =  orientation(i,frame) - 360;
    elseif  (orientation(i,frame)) < -180
        orientation(i,frame) =  orientation(i,frame) + 360;
    end


    % check for flips
    if AngularDifference(orientation(i,frame),orientation(i,frame-1)) > 90
        if FlySeperation(i,otherfly,posx(:,frame),posy(:,frame),MajorAxis(:,frame),MinorAxis(:,frame),orientation(:,frame)) < 20
            if debugstatus
                disp('A large change, close to another fly--suspicious. flip back')
            end
            if AngularDifference(FlipOrientation(orientation(i,frame)),orientation(i,frame-1)) < 30
                % the flipped orientation seems good
                orientation(i,frame) = FlipOrientation(orientation(i,frame));
                theseflies(i,:,:) = flipud(squeeze(theseflies(i,:,:)));
            else
                % use the old one
                orientation(i,frame) = orientation(i,frame-1);
            end

        else
            if debugstatus
                disp('large change, but other fly far away. I will check for extenuating factors like wing extensiton or looking at other fly in the alst 5 frames to override wing-based detection.')
            end
            if any([LookingAtOtherFly(i,frame-5:frame-1) WingExtention(i,frame-5:frame-1)]);
                if debugstatus
                    disp('Overriding wing-based detection!!! restoring original orientation...')
                end
                orientation(i,frame) = FlipOrientation(orientation(i,frame));
                theseflies(i,:,:) = flipud(squeeze(theseflies(i,:,:)));
            end

        end
    end

    
    % % special check for colliding flies/copulating flies
    % if mean(SeparationBetweenFlies(arena,frame-5:frame)) < 10 
    %     % colliding flies, for some time
    %     if ~LookingAtOtherFly(i,frame-1) && ~LookingAtOtherFly(otherfly,frame-1)
    %         % neither fly is looking at each other. fishy. so one of them is probably turned around

            
    %         if any(sum(LookingAtOtherFly([i otherfly],frame-20:frame-1)))
    %             % one fly was looking at the other sometime...
    %             [~,probflip]=max(sum(LookingAtOtherFly([i otherfly],frame-20:frame-1)'));
    %             keyboard
    %         end
    %     end
        

    % end
    
  
end

