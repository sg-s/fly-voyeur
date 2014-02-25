% ComputeCopulationMetrics.m
% computes if copulation occured, when it started, and when it ended, based
% on data from Track2. 
% explanation:
% copulation success is 1 or 0
% copulationstart is the time in seconds from when the flies were introduced. (it's the copulation latency)
% copulation start frame is the frame in the video when copulation starts
function [CopulationSuccess,CopulationStart,CopulationStartFrame,nCollisions,CollisionTime] = ComputeCopulationMetrics4(filename)

load(filename)    
%% global parameters
closecutoff = 50;

disp('Figuring out copulation statistics...')


% create data structures
CopulationSuccess = zeros(1,narenas);
CopulationStart = zeros(1,narenas);
CopulationStartFrame = zeros(1,narenas);
nCollisions = zeros(1,narenas);
CollisionTime = zeros(1,narenas);

for i = 1:narenas
    disp('Arena:')
    disp(i)
    thisfly = i*2-1;
    otherfly= 2*i;

    % determine if they copulate or not. copulation is defined as flies being together for the last 5 seconds of the video. 
    a =  StopTracking-5*30-1;
    z = StopTracking-1;

    if ~max(max(flymissing(thisfly:otherfly,a:z)))
        disp('No flies missing.')
        cop = adjacency(thisfly,:)+adjacency(otherfly,:);
        cop(cop>1)=1;
        if min(cop(a:z))
            if sum(sqrt((posx(thisfly,a:z)-posx(otherfly,a:z)).^2 + (posy(thisfly,a:z)-posy(otherfly,a:z)).^2))/(z-a) < closecutoff
                disp('OK, they are copulating.')
                CopulationSuccess(i) = 1;
            else
                disp('adjacency says they are copulating, but distance is off..weird??')
                keyboard
            end
        end
    else
        disp('Flies missing')
        cop = adjacency(thisfly,:)+adjacency(otherfly,:);
    
        % correct for mysteriously missing flies
        cop = cop + max(flymissing((thisfly):otherfly,:));

        cop(cop>1)=1;
        if sum(cop(a:z))<z-a
            % doesn’t look like it, but let's be sure. 
            if max(sqrt((posx(thisfly,a:z)-posx(otherfly,a:z)).^2 + (posy(thisfly,a:z)-posy(otherfly,a:z)).^2))< closecutoff
                disp('flies are very close together, but i dont think they are copulating')
                keyboard
            else
                % we are sure there is no copulation. 

                CopulationSuccess(i) = 0;
            end
        else
            disp('hmm.copulation! but some flies were missing...')
            keyboard
        end
    end

end

for i = 1:narenas
    thisfly = i*2-1;
    otherfly= 2*i;
    if CopulationSuccess(i)
        % figure out when copulation starts.
        cop = adjacency(thisfly,:)+adjacency(otherfly,:);
    
        % correct for mysteriously missing flies
        cop = cop + max(flymissing((thisfly):otherfly,:));

        cop(cop>1)=1;

        % heal breaks and remove flashes
        cop = filtfilt(ones(1,30)/30,1,cop);
        cop(cop<0.5)=0;
        cop(cop>0)=1;

        disp('Arena:')
        disp(i)
        CopulationStartFrame(i) = find(cop==0,1,'last')
        switch i
        case 1
            CopulationStart(1) = (CopulationStartFrame(1) - LeftStart)/30;
        case 2
            CopulationStart(2) = (CopulationStartFrame(2) - RightStart)/30;
        end

    end

 end


if CopulationStartFrame(1) == 0 
    CopulationStartFrame(1) =  StopTracking;
    CopulationStart(1) = (CopulationStartFrame(1) - LeftStart)/30;
end


if CopulationStartFrame(2) == 0 
    CopulationStartFrame(2) =  StopTracking;
    CopulationStart(2) = (CopulationStartFrame(2) - RightStart)/30;
end

for i = 1:narenas
    thisfly = i*2-1;
    otherfly= 2*i;
    cop = adjacency(thisfly,:)+adjacency(otherfly,:);
    
    % correct for mysteriously missing flies
    cop = cop + max(flymissing((thisfly):otherfly,:));

    cop(cop>1)=1;

    % heal breaks and remove flashes
    cop = filtfilt(ones(1,30)/30,1,cop);
    cop(cop<0.5)=0;
    cop(cop>0)=1;

    [ons,offs]=ComputeOnsOffs(cop);
    ons(ons>CopulationStartFrame(i)) = [];
    offs(offs>CopulationStartFrame(i)) = [];
    nCollisions(i) = length(ons);
    CollisionTime(i) = (sum(cop(StartTracking:CopulationStartFrame(i))))/(CopulationStartFrame(i)-  StartTracking);
end