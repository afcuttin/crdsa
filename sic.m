function [outRandomAccessFrame,ackedPcktsCol,ackedPcktsRow] = sic(inRandomAccessFrame,nonCollPcktsCol,nonCollPcktsRow)
% function [outRandomAccessFrame,ackedPcktsCol,ackedPcktsRow] = sic(inRandomAccessFrame,nonCollPcktsCol,nonCollPcktsRow)
% 
% perform Successive Interference Cancellation (SIC) on a given Random Access Frame for Contention Resolution Diversity Slotted Aloha
% 
% +++ Input parameters
% 		- inRandomAccessFrame: the matrix containing slots and packets informations
% 		- nonCollPcktsCol: an array containing the column indexes of packets that did not encounter collision (can include acked twins)
% 		- nonCollPcktsRow: an array containing the row indexes of packets that did not encounter collision (can include acked twins)
% 
% +++ Output parameters
% 		- outRandomAccessFrame: the matrix containing slots and packets informations, after SIC
% 		- ackedPcktsCol: an array containing the column indexes of acknowledged packets after SIC
% 		- ackedPcktsRow: an array containing the row indexes of acknowledged packets after SIC

nonCollPacketIdx = 1;
while nonCollPacketIdx < numel(nonCollPcktsCol)
    twinPcktCol = inRandomAccessFrame( nonCollPcktsRow(nonCollPacketIdx),nonCollPcktsCol(nonCollPacketIdx) ); % get twin packet slot id

    if sum(inRandomAccessFrame(:,twinPcktCol)>0) > 1 % twin packet has collided
        inRandomAccessFrame(nonCollPcktsRow(nonCollPacketIdx),twinPcktCol) = 0; % cancel twin packet, thus reducing interference
        if sum(inRandomAccessFrame(:,twinPcktCol)>0) == 1; % check if a new package can be acknowledged, thanks to interference cancellation
            nonCollPcktsCol(numel(nonCollPcktsCol) + 1) = twinPcktCol; % update non collided packets col and row indexes arrays
            nonCollPcktsRow(numel(nonCollPcktsRow) + 1) = find(inRandomAccessFrame(:,twinPcktCol));
        end
    elseif sum(inRandomAccessFrame(:,twinPcktCol)>0) == 1 % twin packet has not collided, row and col indexes can be removed from the respective arrays
        nonCollTwinInd = find(nonCollPcktsCol == twinPcktCol);
        nonCollPcktsCol(nonCollTwinInd) = [];
        nonCollPcktsRow(nonCollTwinInd) = [];
    end
    nonCollPacketIdx = nonCollPacketIdx + 1;
end    
outRandomAccessFrame = inRandomAccessFrame;
ackedPcktsCol = nonCollPcktsCol;
ackedPcktsRow = nonCollPcktsRow;