% wing extension processing script
thisarena = 2;

we = WingExtention(thisarena*2,:) + WingExtention(2*thisarena-1,:);
we(isnan(we)) = 0;

lwe = filtfilt(ones(1,10)/10,1,we);





return
thisarena = 1;

we = WingExtention(thisarena*2,:) + WingExtention(2*thisarena-1,:);
we = abs(we);
we(isnan(we)) = 0;
lwe = log(we);
lwe(lwe<log(10)) = 0;


% throw away small signals
lwe(lwe<4) = 0 ;

% smooth over 5 frames
lwe = filtfilt(ones(1,10)/10,1,lwe);


% throw away small signals
lwe(lwe<4) = 0 ;


% bout by bout analysis and validation
dlwe = lwe;
dlwe(dlwe>0)=1;
dlwe = diff(dlwe);
ons = find(dlwe==1);
offs = find(dlwe==-1);

% make sure this is OK
if ons(1) < offs(1)

else
	ons = [StartTracking ons];
end

if ons(end) > offs(end)
	offs = [offs StopTracking];
end

if length(ons) ~= length(offs)
	error
end

deletethis = 0*ons;
for i = 1:length(ons)
	thisbout = lwe(ons(i)+1:offs(i));
	if sum(thisbout) < 200 || length(thisbout) < 30
		deletethis(i)=1;
	end
end
lwe2 = lwe;
% delete crappy bouts
for i = 1:length(ons)
	if deletethis(i)
		lwe2(ons(i)+1:offs(i)) = 0;
	end
end

lwe2(lwe2>0)=1;
lwe(lwe>0) = 1;
figure, hold on, plot(lwe), hold on
plot(lwe2,'r')