function  []  = UpdateDisplay(v,frame,ff,flymissing,posx,posy,WingExtention,orientation,heading,t,StartFromHere,collision)
n= size(posx,1);
if v
    figure(gcf);
    cla
    imagesc(ff), hold on, axis image
    che = 0;
    for i = 1:n
        if flymissing(i,frame)
            scatter(posx(i,frame),posy(i,frame),'r','filled')
            che = che+1;
        else
            triangle([posx(i,frame) posy(i,frame)],orientation(i,frame),10,'k');
            triangle([posx(i,frame) posy(i,frame)],heading(i,frame),10,'b');
            che = che+1;
        end

    end
    if che~=n
        keyboard
    end


    tt=toc(t);
    fps = oval((frame-StartFromHere)/tt,3);
    cf = [];
    if any(WingExtention(:,frame))
        scatter(posx(find(WingExtention(:,frame)),frame),posy(find(WingExtention(:,frame)),frame),1500,'g')
        scatter(posx(find(WingExtention(:,frame)),frame),posy(find(WingExtention(:,frame)),frame),1600,'g')
    else
        if any(collision(:,frame))
            cf = mat2str(find(collision(:,frame)));
            title(strkat('Frame ', mat2str(frame),' at ', fps , 'fps. Colliding flies:',cf));
        else
            title(strkat('Frame ', mat2str(frame),' at ', fps , 'fps.'));
        end
    end


else
    if rand > 0.95
        tt=toc(t);
        fps = oval((frame-StartFromHere)/tt,3);
        fprintf(strkat('\n Frame # ', mat2str(frame), '   @ ', fps, 'fps'));
    end
end



  
