% determines is each fly is looking at the other fly in the arena. uses information about position, orientation, and major and minor axes. 
% created by Srinivas Gorur-Shandilya at 13:02 , 09 February 2014. Contact me at http://srinivas.gs/contact/
function [FlyLookingAtOtherFly] = IsFlyLookingAtOtherFly(posx,posy,MajorAxis,MinorAxis,orientation)
FlyLookingAtOtherFly = 0*posx;
for i = 1:length(posx)
	switch i 
        case 1
            otherfly= 2;
        case 2
            otherfly= 1;
        case 3
            otherfly= 4;
        case 4
            otherfly= 3;
    end

    % find four ends of the otherfly's ellipse
    head(1) = cosd(orientation(otherfly))*(MajorAxis(otherfly)/2) + posx(otherfly);
    head(2) = sind(orientation(otherfly))*(MajorAxis(otherfly)/2) + posy(otherfly);
    tail(1) = -cosd(orientation(otherfly))*(MajorAxis(otherfly)/2) + posx(otherfly);
    tail(2) = -sind(orientation(otherfly))*(MajorAxis(otherfly)/2) + posy(otherfly);


    left(1) = -sind(orientation(otherfly))*(MinorAxis(otherfly)/2) + posx(otherfly);
    left(2) = cosd(orientation(otherfly))*(MinorAxis(otherfly)/2) + posy(otherfly);
    right(1) = sind(orientation(otherfly))*(MinorAxis(otherfly)/2) + posx(otherfly);
    right(2) = -cosd(orientation(otherfly))*(MinorAxis(otherfly)/2) + posy(otherfly);

    % find angles from these points to the centre of this fly
    angles(1) = atan2d(head(2) - posy(i),head(1) - posx(i));
    angles(2) = atan2d(tail(2) - posy(i),tail(1) - posx(i));
    angles(3) = atan2d(left(2) - posy(i),left(1) - posx(i));
    angles(4) = atan2d(right(2) - posy(i),right(1) - posx(i));


    angles(angles<0) = angles(angles<0)+360; 
    if orientation(i)<0
        thisflyo = orientation(i) + 360;
    else
        thisflyo = orientation(i);
    end

    if thisflyo > min(angles) && thisflyo < max(angles)
        %disp('I think this fly is looking at the other fly.')
        FlyLookingAtOtherFly(i) = 1;
        
    else
        %disp('I DONT think this fly is looking at the other fly.')
        
    end


end