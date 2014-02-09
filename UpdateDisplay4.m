function  []  = UpdateDisplay4(v,frame,ff,flymissing,posx,posy,WingExtention,orientation,heading,t,StartFromHere,collision,MajorAxis,MinorAxis,LookingAtOtherFly,displayfigure)
n= size(posx,1);
if v
    figure(displayfigure);
    cla
    imagesc(ff), hold on, axis image
    che = 0;
    
    for i = 1:n
        if flymissing(i,frame)
            scatter(posx(i,frame),posy(i,frame),'r','filled')
            che = che+1;
        else
            % indicate major and minor axes
            head(1) = cosd(orientation(i,frame))*(MajorAxis(i,frame)/2) + posx(i,frame);
            head(2) = sind(orientation(i,frame))*(MajorAxis(i,frame)/2) + posy(i,frame);
            tail(1) = -cosd(orientation(i,frame))*(MajorAxis(i,frame)/2) + posx(i,frame);
            tail(2) = -sind(orientation(i,frame))*(MajorAxis(i,frame)/2) + posy(i,frame);
            line([head(1) tail(1)], [head(2) tail(2)],'LineWidth',1,'Color','k')

            left(1) = -sind(orientation(i,frame))*(MinorAxis(i,frame)/2) + posx(i,frame);
            left(2) = cosd(orientation(i,frame))*(MinorAxis(i,frame)/2) + posy(i,frame);
            right(1) = sind(orientation(i,frame))*(MinorAxis(i,frame)/2) + posx(i,frame);
            right(2) = -cosd(orientation(i,frame))*(MinorAxis(i,frame)/2) + posy(i,frame);
            line([left(1) right(1)], [left(2) right(2)],'LineWidth',1,'Color','k')

            if LookingAtOtherFly(i,frame)
                triangle([posx(i,frame) posy(i,frame)],orientation(i,frame),10,'k',3);
            else
                triangle([posx(i,frame) posy(i,frame)],orientation(i,frame),10,'k');
            end
            che = che+1;
            if abs(WingExtention(i,frame)) > 0
                text(posx(i,frame)-50,posy(i,frame)-50,oval(abs(WingExtention(i,frame)),2),'BackgroundColor',[1 1 1]);
            end
        end

    end

    if che~=n
        error('Some awful error')
    end


    tt=toc(t);
    fps = oval((frame-StartFromHere)/tt,3);
    cf = [];
    if any(WingExtention(:,frame))
        scatter(posx(find(WingExtention(:,frame)),frame),posy(find(WingExtention(:,frame)),frame),1500,'g')
        scatter(posx(find(WingExtention(:,frame)),frame),posy(find(WingExtention(:,frame)),frame),1600,'g')

         
        
    end
    if any(collision(:,frame))
        cf = mat2str(find(collision(:,frame)));
        title(strkat('Frame ', mat2str(frame),' at ', fps , 'fps. Colliding flies:',cf));
    else
        title(strkat('Frame ', mat2str(frame),' at ', fps , 'fps.'));
    end



else
    if rand > 0.95
        tt=toc(t);
        fps = oval((frame-StartFromHere)/tt,3);
        fprintf(strkat('\n Frame # ', mat2str(frame), '   @ ', fps, 'fps'));
    end
end



  
