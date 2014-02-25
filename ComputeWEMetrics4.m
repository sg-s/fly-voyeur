% ComputeWEMetrics.m
% created by Srinivas Gorur-Shandilya at 18:34 , 12 November 2013. Contact
% me at http://srinivas.gs/contact/
function [FirstWE, TotalWE,WE] = ComputeWEMetrics4(filename,CopulationStartFrame,OnlyDoTillXMinutes)

% prep output
FirstWE = zeros(2,1);
TotalWE = zeros(2,1);


% load the file
load(filename)

WE = WingExtention;

narenas = 2;

for thisarena = 1:narenas
    we = WingExtention(thisarena*2,:) + WingExtention(2*thisarena-1,:);


    % remove WE after CopulationStart
    we(CopulationStartFrame(thisarena):end)=0;
    we(isnan(we)) = 0;
    % smooth over 5 frames
    we = filtfilt(ones(1,10)/10,1,we);
    we = abs(we);
    

    m = mean(nonzeros(we));
    s = std(nonzeros(we));

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

    % heal breaks
    lwe  = filtfilt(ones(1,30)/30,1,lwe);
    lwe(lwe<0.5) = 0;
    lwe(lwe>0) = 1;

    if m < 1000
        disp('maybe the fly never extended a wing? fishy')

        if sum(y(1:15)) > sum(y(16:end))
            WEpeak =find(y==max(y((mins(end)):end)),1,'first');
            cutoff = x(WEpeak) - (x(WEpeak) - x(mins(end)));

        else
            disp('I thought there was no WE at all, but my distribution says otherwise')
            cutoff = x(find(y>max(y)/2,1,'first')-1);
        end

    else
        
        if length(maxs)==2 && length(mins) == 1
            if maxs(1) < mins && mins < maxs(2)
                % bimodal distribution. we find the cutoff between the peaks. 
                maxs = max(maxs);
                mins(mins>maxs) = [];
                mins = max(mins);
                cutoff = x(maxs)-(x(maxs)-x(mins))/2;




            else
                disp('funny distribution2')
                keyboard
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
            disp('funny distribution. I will try to smooth the histogram to find a nice cut')

            keyboard
        end

        

    end
    lwe(lwe<cutoff)= 0;
    lwe(lwe>cutoff)=1;

    % remove wing extension bouts longer than 30seconds...that's probably a bad collision
    [ons,offs]=ComputeOnsOffs(lwe); 
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
    
    FirstWE(thisarena) = (find(lwe==1,1,'first')-StartTracking)/30;

    if FirstWE(thisarena) < 0
        FirstWE(thisarena) =0; 
    end

    WE(thisarena,:) = lwe;

end



