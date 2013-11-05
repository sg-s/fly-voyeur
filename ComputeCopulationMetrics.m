% ComputeCopulationMetrics.m
% computes if copulation occured, when it started, and when it ended, based
% on data from Track2. 
function [Copulation,CopulationTimes] = ComputeCopulationMetrics(posx,posy,collision,narenas)
%% global parameters
S = 3;
C = 5;
CopThresh = 150; % 5 seconds
ComplexBreak = 50; % the ratio of long collision duration to breka between to qualify that they are all part of the same copulation event


if any(~isnan(posx(1,:)))
    % create data structures
    CopulationTimes = zeros(1,narenas);
    Copulation = zeros(narenas,length(posx));
    for i = 1:narenas
        % merge collision data
        cop = collision(2*i-1,:)+collision(2*i,:);
        cop(cop>1)=1;

        % find collision statistics
        [ons,offs]=ComputeOnsOffs(cop);

        % remove collisions shorter than C frames
        CollisionDurations = (offs)-(ons);
        for j = 1:length(CollisionDurations)
            if CollisionDurations(j)<C
                cop(ons(j):offs(j)) = 0;
            end
        end
        % update collision statistics
        [ons,offs]=ComputeOnsOffs(cop);

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
                cop(ons(j):offs(j)) = 1;
            end
        end

        [ons,offs]=ComputeOnsOffs(cop);
        CollisionDurations = (offs)-(ons);

        if max(CollisionDurations) < CopThresh
            % no copulation
        else
            if sum((CollisionDurations>CopThresh)) == 1
                % just one long collision. the beginning of this is copulation
                CopulationTimes(i) = ons(CollisionDurations>CopThresh); % frame #
            else
                % hard case. there are mulitple, long collisions. which one is the actual copulation? 
                % see is there is one value that stands out
                if sum(CollisionDurations>mean(CollisionDurations)) == 1
                    % yes! use. this.
                    CopulationTimes(i) = ons((CollisionDurations>mean(CollisionDurations)));
                else
                    % bummer. 
                    % grab a list of all the long collision durations
                    LongCollisions = find(CollisionDurations>mean(CollisionDurations));

                    % are they all adjacent? 
                    if LongCollisions(1)+length(LongCollisions)-1 == LongCollisions(end)
                        % find all the seperations between them
                        AnnoyingSeperations = SeperationDurations(LongCollisions(1:end-1));
                        % if the seperations are very short compared to the collisions, then use the first long collision
                        if mean(CollisionDurations(LongCollisions))/mean(AnnoyingSeperations) > ComplexBreak
                            % use the first collision event
                            CopulationTimes(i) = ons(LongCollisions(1));
                        else
                            disp('something wrong')
                            keyboard
                        end


                    else
                        disp('non-adjacent multiple long collisions')
                        keyboard
                    end
                end
            end
        end

        Copulation(i,:) = cop;
    end

end
    

