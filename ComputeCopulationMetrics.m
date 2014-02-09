% ComputeCopulationMetrics.m
% computes if copulation occured, when it started, and when it ended, based
% on data from Track2. 
function [CopulationTimes] = ComputeCopulationMetrics(adjacency,narenas,flymissing,filename)
%% global parameters
S = 30; % 1 second
C = 5;
CopThresh = 200; % 5 seconds
ComplexBreak = 50; % the ratio of long adjacency duration to breka between to qualify that they are all part of the same copulation event



% create data structures
CopulationTimes = zeros(1,narenas);
for i = 1:narenas
    % merge adjacency data
    cop = adjacency(2*i-1,:)+adjacency(2*i,:);
    
    % correct for mysteriously missing flies
    cop = cop + max(flymissing((2*i-1):2*i,:));

    cop(cop>1)=1;

    % find adjacency statistics
    [ons,offs]=ComputeOnsOffs(cop);


    % remove seperations shorter than S frames
    if ~isempty(ons)
        ons(1)=[];
        offs(end) =[];
        SeperationDurations = ons-offs;
        if min(SeperationDurations< 0)
            error('-ve sep.')

        end
        for j = 1:length(SeperationDurations)
            if SeperationDurations(j)<S
                cop(offs(j):ons(j)) = 1;
            end
        end
    end
    % update adjacency statistics
    [ons,offs]=ComputeOnsOffs(cop);
    
    % remove collisions shorter than C frames
    CollisionDurations = (offs)-(ons);
    for j = 1:length(CollisionDurations)
        if CollisionDurations(j)<C
            cop(ons(j):offs(j)) = 0;
        end
    end
    
    % iterative removal of seperations.
    % as we progress in time, if the seperation duration is less than 1/10
    % that of the previous collision duration, we remove it. 
    goon =1;
    while goon
        % caclulate metrics
        [ons,offs]=ComputeOnsOffs(cop); 
        CollisionDurations = (offs)-(ons);
        if ~isempty(ons)
            ons(1)=[];
            offs(end) =[];
            SeperationDurations = ons-offs;

            if any(CollisionDurations(1:end-1)./SeperationDurations > 10)
                % seperation that can be deleted. redo
                deletethese=find(CollisionDurations(1:end-1)./SeperationDurations > 10);
                for j = deletethese
                    cop(offs(j):ons(j)) = 1;
                end

            else
                % all good
                goon=0;
            end
        else
            goon=0;
        end
        
    end
    
    
    
    [ons,offs]=ComputeOnsOffs(cop);
    CollisionDurations = (offs)-(ons);
    SeperationDurations= []; % no longer valid

    if (max(CollisionDurations) < CopThresh) 
        % no copulation
    elseif ~isempty(CollisionDurations)
        if sum((CollisionDurations>CopThresh)) == 1
            % just one long adjacency. the beginning of this is copulation
            CopulationTimes(i) = ons(CollisionDurations>CopThresh); % frame #
        else
            % hard case. there are mulitple, long collisions. which one is the actual copulation? 
            % see is there is one value that stands out
            if sum(CollisionDurations>2*mean(CollisionDurations)) == 1
                % yes! use. this.

               CopulationTimes(i) = ons((CollisionDurations>2*mean(CollisionDurations)));

            else
                % bummer. 
                % we should never reach this case
                warning('Something horribly wrong. Picking last collision...')
                disp('I think this is when copulation starts:')
                
                LongCollisions = find(CollisionDurations>mean(CollisionDurations));
                ons(LongCollisions(end))
                CopulationTimes(i) = ons(LongCollisions(end));
                %CopulationTimes(i) = ons(end);
                ShowTracking(filename,ons(LongCollisions(end)));
                keyboard
                
                
            end
        end
    end


end

    

