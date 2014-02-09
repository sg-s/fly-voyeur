% finds colliding flies, in arenas with 3 flies
function [SplitThisFly] = FindPutativeCollidingFlies3(thisarena,collision,flymissing,frame,area)
SplitThisFly = [];
% figure out the flies in question
thisfly = 3*thisarena;
otherfly = 3*thisarena-1;
thirdfly = otherfly-1;
theseflies = [thirdfly:thisfly];

% find the fracitonal change in areas
da = area(thirdfly:thisfly,frame)./area(thirdfly:thisfly,frame-1);
% how many flies are missing?
switch sum(flymissing(thirdfly:thisfly,frame))
	case 0
		% no flies missing. 
		return
	case 1
		% one fly missing. 
		% is one of the other flies suddenly bigger? 
		if length(find(da > 1.5)) == 1
			SplitThisFly(1) = theseflies(da>1.5);
			SplitThisFly(2) = theseflies(find(flymissing(thirdfly:thisfly,frame)));
		end
	case 2
		disp('two flies missing')
		% is the non-missing fly huge?
		if length(find(da > 2.5)) == 1
			SplitThisFly(1) = theseflies(da>1.5);
			disp('two flies are missing, and I dont know what to do. line 29, FindPutativeCollidingFlies3')
			keyboard
		
		end
	case 3
		% all flies missing
		return
end
    

    