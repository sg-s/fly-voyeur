function [ManualWE] = LearnWEParameters2(flypics)
%% make a simple GUI that shows the image, with two buttons: yes WE or no WE
ManualWE = NaN(1,length(flypics));
f1 = figure('Position',[250 250 900 600],'Toolbar','none','Menubar','none','NumberTitle','off','Resize','off','HandleVisibility','on');
YesButton = uicontrol(f1,'Position',[573 5 80 30],'Style','pushbutton','String','YES','Callback',@LearnYESResponse);
NoButton = uicontrol(f1,'Position',[273 5 80 30],'Style','pushbutton','String','NO','Callback',@LearnNOResponse);
imagesc(flypics(:,:,1))
frame=1;
while any(isnan(ManualWE))
    pause(0.01)
end
function [] = LearnYESResponse(eo,ed)
    ManualWE(frame) = 1;
    figure(f1),axis image
    frame = frame+1;
    if frame > length(flypics)
        return
    else
        imagesc(flypics(:,:,frame))
    end
end


function [] = LearnNOResponse(eo,ed)
    ManualWE(frame) = 0;
    figure(f1),axis image
    frame = frame+1;
    if frame > length(flypics)
        return
    else
        imagesc(flypics(:,:,frame))
    end
    
end

end