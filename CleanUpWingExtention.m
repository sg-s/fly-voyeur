% CleanUpWingExtention.m
function [WingExtention,Copulation,CopulationTimes] = CleanUpWingExtention(posx,posy,collision,WingExtention,narenas)
% first figure out the copulations
[Copulation,CopulationTimes] = ComputeCopulationMetrics(posx,posy,collision,narenas);

%% global parameters
S = 3;
C = 8;
sz = size(WingExtention);
for i = 1:sz(1)
    % for each fly
    
    % remove all times spent copulating (colliding)
    thisarena = ceil(i/2);
    WingExtention(i,:) = WingExtention(i,:).*Copulation(thisarena,:);
    

    % find extention statistics
    if any(WingExtention(i,:))
        [ons,offs]=ComputeOnsOffs(WingExtention(i,:));

        % remove extentions shorter than C frames
        ExtentionDurations = (offs)-(ons);
        for j = 1:length(ExtentionDurations)
            if ExtentionDurations(j)<C
                WingExtention(i,ons(j):offs(j)) = 0;
            end
        end
    
        % update collision statistics
        if any(WingExtention(i,:))
            [ons,offs]=ComputeOnsOffs(WingExtention(i,:));

            % remove seperations shorter than S frames
            ons(1)=[];
            offs(end) =[];
            SeperationDurations = ons-offs;
            if min(SeperationDurations< 0)
                disp('-ve sep.')
                keyboard
            end 
            for j = 1:length(SeperationDurations)
                if SeperationDurations(j)<S
                    WingExtention(i,ons(j):offs(j)) = 1;
                end
            end
            if any(WingExtention(i,:))
                [ons,offs]=ComputeOnsOffs(WingExtention(i,:));
                ExtentionDurations = (offs)-(ons);
            end
        end
    end

    
end



        

       