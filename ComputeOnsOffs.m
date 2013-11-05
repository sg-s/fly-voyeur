function [ons,offs] = ComputeOnsOffs(cop)
ons = diff(cop);
offs = (ons<0);
ons(ons<0) = 0;
ons = find(ons);
offs = find(offs);
% check that collisions happen in the right order
if ons(1) > offs(1)
    disp('something wrong')
    keyboard
end
ons = ons+1; % correct for derivative shift
if length(ons) > length(offs)
	% flies are still colliding at end of movie
	offs = [offs length(cop)];
elseif length(offs) > length(ons)
	keyboard
else
	% all OK
end