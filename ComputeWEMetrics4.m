% ComputeWEMetrics.m
% created by Srinivas Gorur-Shandilya at 18:34 , 12 November 2013. Contact
% me at http://srinivas.gs/contact/
function [FirstWE, TotalWE,WE] = ComputeWEMetrics4(filename,cop,OnlyDoTillXMinutes)

CopulationStartFrame = cop.CopulationStartFrame;
CopulationSuccess = cop.CopulationSuccess;
% prep output
FirstWE = zeros(2,1);
TotalWE = zeros(2,1);
WE = 0;

% load the file
load(filename)

WE = WingExtention;

narenas = 2;



for thisarena = 1:narenas
    thisfly= 2*thisarena;
    otherfly=thisfly-1;


    we = WingExtention(thisarena*2,:) + WingExtention(2*thisarena-1,:);

    % censor WE around missing flies
    for k = 1:length(we)
        m=0;
        try
            m = max(max(flymissing(otherfly:thisfly,k-15:k+15)));
        end
        if m
            we(k) = 0;
        end

    end



    % remove WE after CopulationStart
    we(CopulationStartFrame(thisarena):end)=0;
    we(isnan(we)) = 0;
    % smooth over 5 frames
    we = filtfilt(ones(1,10)/10,1,we);
    we = abs(we);

    m = mean(nonzeros(we));
    mm = max(we);

    we = we/m;
    lwe = log(we) + log(m);

    lwe = lwe/max(lwe);

    % throw away small signals
    lwe(lwe<0) = 0;

    % split the distribution into two
    lwe2 = nonzeros(lwe);
    [y,x]=hist(lwe2,30);
    [~,maxs]=findpeaks(y,'npeaks',2,'minpeakdistance',length(x)/3);
    [~,mins]=findpeaks(-y,'npeaks',2,'minpeakdistance',length(x)/3);

    if length(maxs) == 0 || length(mins)==0
        disp('something totally wrong')
        return
    end






    if m < 1000
        disp('maybe the fly never extended a wing? fishy')

        if sum(y(1:15)) > sum(y(16:end))
            % does it copulate?
            if CopulationSuccess(thisarena)
                WEpeak =find(y==max(y((mins(end)):end)),1,'first');
                cutoff = x(WEpeak) - (x(WEpeak) - x(mins(end)))/2;
            else
                % check the magnitudes of WE
                if mm < 2000
                    cutoff = Inf;
                else
                    disp('There is def. some WE going on...')
                    WEpeak =find(y==max(y((mins(end)):end)),1,'first');
                    cutoff = x(WEpeak) - (x(WEpeak) - x(mins(end)))/3;
                end
            end


        else
            disp('I thought there was no WE at all, but my distribution says otherwise')
            cutoff = x(find(y>max(y)/2,1,'first')-1);
        end

    else
        disp('At least one large WE event...')
        if length(maxs)==2 && length(mins) == 1
            if maxs(1) < mins && mins < maxs(2)
                % bimodal distribution. we find the cutoff between the peaks. 
                maxs = max(maxs);
                mins(mins>maxs) = [];
                mins = max(mins);
                cutoff = x(maxs)-(x(maxs)-x(mins))/2;




            else
                disp('funny distribution, will try to find peaks anyway...')
                [~,maxs]=findpeaks(y,'minpeakdistance',length(x)/3);
                [~,mins]=findpeaks(-y,'minpeakdistance',length(x)/3);
                temp=sort(y(maxs),'descend');
                maxs(y(maxs)<temp(2)) = [];
                % now make sure there is amin b/w
                mins(mins<maxs(1))=[];
                mins(mins>maxs(2))=[];

                if length(mins)==1 && length(maxs) == 2

                    cutpoint = x(find(y==min(y(min(mins):max(maxs))),1,'first'));
                    WEpeak  = x(max(maxs));
                    cutoff = WEpeak - (WEpeak - cutpoint)/2;

                else
                    disp('Funny distrib. Tried to fix, but failed. Will fall back to simply picking a default threshold below the max....')
                    WEpeak = x(max(maxs));
                    cutoff = WEpeak - 0.25;
                end
            end

        elseif min(maxs) < min(mins) && max(maxs) > max(mins)
            % still bimodal.
            cutpoint = x(find(y==min(y(min(mins):max(maxs))),1,'first'));
            WEpeak  = x(max(maxs));
            cutoff = WEpeak - (WEpeak - cutpoint)/2;
        elseif min(maxs) < max(mins) && max(maxs) > max(mins)
            % still bimodal. 
            cutpoint = x(max(mins));
            WEpeak = x(max(maxs));
            cutoff = WEpeak - (WEpeak - cutpoint)/2;
        elseif  min(maxs) < min(mins) && max(maxs) > min(maxs)
            % still bimodal
            cutpoint = x(min(mins));
            WEpeak = x(max(maxs));
            cutoff = WEpeak - (WEpeak - cutpoint)/2;
        else
            disp('funny distribution. Im going to set cutoff to close to the peak and hope for the best....')

            WEpeak = x(max(maxs));
            cutoff = WEpeak - 0.25;
        end

        

    end
    lwe(lwe<cutoff)= 0;
    lwe(lwe>cutoff)=1;

    % heal breaks
    lwe  = filtfilt(ones(1,30)/30,1,lwe);
    lwe(lwe<0.5) = 0;
    lwe(lwe>0) = 1;

    % remove wing extension bouts longer than 30seconds...that's probably a bad collision
    [ons,offs]=ComputeOnsOffs(lwe); 
    if ~isempty(ons)
        if length(ons) == length(offs) && offs(end) > ons(end)
            WEBoutLengths = offs-ons;
            censorthese = find(WEBoutLengths>600);
            for k = 1:length(censorthese)
                lwe(ons(censorthese(k)):offs(censorthese(k))) = 0;
            end
        else
            disp('Something wrong with ons and offs of WE')

            keyboard
        end
    end

    if nargin == 3
        switch thisarena
        case 1
            stophere = min([LeftStart+OnlyDoTillXMinutes*60*30 length(lwe)]);
            t = lwe(StartTracking:stophere);
            z = min([OnlyDoTillXMinutes*60*30+LeftStart CopulationStartFrame(thisarena)]);
            TotalWE(thisarena) = sum(t)/(z - StartTracking);
        case 2
            stophere = min([RightStart+OnlyDoTillXMinutes*60*30 length(lwe)]);
            t = lwe(StartTracking:stophere);
            z = min([OnlyDoTillXMinutes*60*30+RightStart CopulationStartFrame(thisarena)]);
            TotalWE(thisarena) = sum(t)/(z - StartTracking);
        end
    else
        TotalWE(thisarena) = sum(lwe)/(CopulationStartFrame(thisarena) - StartTracking);
    end
    
    if TotalWE(thisarena)
        switch thisarena
        case 1
            FirstWE(thisarena) = (find(lwe==1,1,'first')-LeftStart)/30;
        case 2
            FirstWE(thisarena) = (find(lwe==1,1,'first')-RightStart)/30;
        end

        
    end

    if FirstWE(thisarena) < 0
        FirstWE(thisarena) =0; 
    end

    WE(thisarena,:) = lwe;



    % if strmatch(filename,'2013-12-13 52cTRPA1 Cam1-23.MPG.mat')
    %     keyboard
    % end




end



