% takes fly positions and information about misising or not and assigns objects to flies
% guarantees that every object is assigned to a fly, but does not gaurantee that every fly is 
% assigned to an object
function [assigned_objects] = BuildFly2ObjectMap(posx,posy,flymissing,rp)
assigned_objects = NaN(1,length(posx));
posx(find(flymissing)) = Inf;
for i = 1:length(rp)
    assigned_objects(find(pdist2([rp(i).Centroid(1),rp(i).Centroid(2)],[posx posy])==0))=i;
end