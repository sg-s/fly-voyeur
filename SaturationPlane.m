% created by Srinivas Gorur-Shandilya at 18:14 on 31-March-2014. Contact me at http://srinivas.gs/
% SaturationPlane()
function [s] = SaturationPlane(ff)
ff = double(ff);
s=(1-3*min(ff,[],3)./sum(ff,3));