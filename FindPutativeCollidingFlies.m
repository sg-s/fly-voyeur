% created by Srinivas Gorur-Shandilya at 19:00 , 18 November 2013. Contact
% me at http://srinivas.gs/contact/
% part of the Track3 codebase
function [PutativeCollidingFlies] = FindPutativeCollidingFlies(thisarena,collision,flymissing,frame,area)
PutativeCollidingFlies = [];
% figure out the flies in question
thisfly = 2*thisarena;
otherfly = 2*thisarena-1;

% is there a fly missing?
if any(flymissing(otherfly:thisfly,frame))
    if flymissing(otherfly,frame) && flymissing(thisfly,frame)
        %disp('both flies missing. ')
        return
    else
        %disp('only one fly missing. ')
        missingfly =  intersect(find(flymissing(:,frame)),[otherfly thisfly]);
        mergedfly = setdiff([otherfly thisfly],missingfly);
        
        if area(mergedfly,frame)/area(mergedfly,frame-1) > 1.4
            if (collision(mergedfly,frame)*collision(missingfly,frame)) %#ok<BDLOG>
                PutativeCollidingFlies = [mergedfly missingfly];
            elseif (flymissing(mergedfly,frame)*flymissing(missingfly,frame))
                % both flies missing in last frame, and one monster fly re-appears? fishy.
                PutativeCollidingFlies = [mergedfly missingfly];
            end
        end
        
    end
else
    %disp('no flies missing, cant be a collision')
    return
end

    