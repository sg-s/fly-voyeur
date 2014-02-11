Open bugs in track

1. when flies groom, or otherwise move wings, orientation can flip. can we use a symmetric, scan of the sides (front and back) to figure out the locations of the wings and then check for orientation flip?

2. when flies collide, orientation is fucked, and can even reverse. 

what should the orientation policy be?

- always trust wing-based orientation, EXCEPT when fly is very close another fly (use actual minimum distance)