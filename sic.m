function [outRandomAccessFrame,ackedPcktsCol,ackedPcktsRow] = sic(raf,maxIter)
% function [outRandomAccessFrame,ackedPcktsCol,ackedPcktsRow] = sic(inRandomAccessFrame,nonCollPcktsCol,nonCollPcktsRow,capture)
%
% perform Successive Interference Cancellation (SIC) on a given Random Access Frame for Contention Resolution Diversity Slotted Aloha
%
% +++ Input parameters
% 		- raf: the structure of matrices containing slots and packets informations
% 		- maxIter: the maximum number of times the Successive Interference Cancelation can be performed
%
% +++ Output parameters
% 		- outRandomAccessFrame: the structure of matrices containing slots and packets informations, after SIC
% 		- ackedPcktsCol: an array containing the column indices of acknowledged packets after SIC
% 		- ackedPcktsRow: an array containing the row indices of acknowledged packets after SIC

if ~exist('maxIter','var')
    % perform complete interference cancelation, maxIter is set equal to the number of active sources
    maxIter = nnz(sum(raf.status,2));
end

iterCounter       = 0;
ackedPcktsCol     = [];
ackedPcktsRow     = [];
raf.slotStatus    = sum(raf.status) == 1;
newCleanBurstSlot = find(sum(raf.status) == 1);

if numel(newCleanBurstSlot) > 0

    while sum(raf.slotStatus) ~= 0 && iterCounter <= maxIter

        iterCounter = iterCounter + 1;
        cleanBurstSlot = newCleanBurstSlot;
        newCleanBurstSlot = [];

        i=1;
        while i <= numel(cleanBurstSlot)
            cleanBurstRow = find(raf.status(:,cleanBurstSlot(i)));
            % update the list of acked bursts
            ackedPcktsCol = [ackedPcktsCol,cleanBurstSlot(i)];
            ackedPcktsRow = [ackedPcktsRow,cleanBurstRow];
            % update statuses
            raf.status(cleanBurstRow,cleanBurstSlot(i)) = 0;
            raf.slotStatus(cleanBurstSlot(i))           = 0;
            % proceed with the interference cancelation
            twinPcktCol = raf.twins{ cleanBurstRow,cleanBurstSlot(i) };

            for twinPcktIdx = 1:length(twinPcktCol)

                raf.status(cleanBurstRow,twinPcktCol(twinPcktIdx)) = 0; % interference cancelation

                if sum(raf.status(:,twinPcktCol(twinPcktIdx))) == 0 % twin burst was a clean burst
                    nonCollTwinInd = find(cleanBurstSlot == twinPcktCol(twinPcktIdx));
                    if ~isempty(nonCollTwinInd)
                        cleanBurstSlot(nonCollTwinInd) = []; %remove the twin burst from the acked bursts list
                    end
                    nonCollTwinInd = find(newCleanBurstSlot == twinPcktCol(twinPcktIdx));
                    if ~isempty(nonCollTwinInd)
                        newCleanBurstSlot(nonCollTwinInd) = []; %remove the twin burst from the acked bursts list
                    end
                    raf.slotStatus(twinPcktCol(twinPcktIdx))  = 0;
                elseif sum(raf.status(:,twinPcktCol(twinPcktIdx))) == 1 % a new burst is clean, thanks to interference cancellation
                    newCleanBurstSlot = [newCleanBurstSlot,twinPcktCol(twinPcktIdx)];
                    raf.slotStatus(twinPcktCol(twinPcktIdx))  = 1;
                else % sum(raf.status(:,twinPcktCol(twinPcktIdx))) > 1
                    % at least two bursts are colliding: do nothing
                end
            end
            i = i + 1;
        end
    end

    outRandomAccessFrame = raf.status;

elseif numel(newCleanBurstSlot) == 0

    warning('Nothing to do here, exiting')
    outRandomAccessFrame = raf.status;
    ackedPcktsCol = [];
    ackedPcktsRow = [];

end