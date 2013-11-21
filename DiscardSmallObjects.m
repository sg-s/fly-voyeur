function [regions] = DiscardSmallObjects(regions,min_area)
% part of the Track3 codebase.
% throw out small objects
badregion = [regions.Area] < min_area;
regions(badregion) = [];
    