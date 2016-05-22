function [outRandomAccessFrame,ackedPcktsCol,ackedPcktsRow] = sic(raf,maxIter,capture)
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

iterCounter   = 0;
ackedPcktsCol = [];
ackedPcktsRow = [];

if nnz(raf.slotStatus) > 0
    newCleanBurstSlot = find(raf.slotStatus);
elseif nnz(raf.slotStatus) == 0 % check if at least one clean burst exists
    raf.slotStatus    = int8(sum(raf.status) == 1);
    newCleanBurstSlot = find(raf.slotStatus);
end

if numel(newCleanBurstSlot) > 0

    while sum(raf.slotStatus == 1) ~= 0 && iterCounter <= maxIter

        iterCounter       = iterCounter + 1;
        cleanBurstSlot    = newCleanBurstSlot;
        newCleanBurstSlot = [];

        i=1;
        while i <= numel(cleanBurstSlot)
            burstsInSlot = find(raf.status(:,cleanBurstSlot(i)));
            burstsInSlotNum = numel(burstsInSlot);
            if burstsInSlotNum > 1 % capture scenario
                cleanBurstRow = burstCapture(cleanBurstSlot(i),raf,capture)
            elseif burstsInSlotNum == 1 % no capture scenario
                cleanBurstRow = burstsInSlot;
            else
                error('Something is wrong here with the SIC');
            end
            % update the list of acked bursts
            ackedPcktsCol = [ackedPcktsCol,cleanBurstSlot(i)];
            ackedPcktsRow = [ackedPcktsRow,cleanBurstRow];
            % update statuses
            raf.status(cleanBurstRow,cleanBurstSlot(i))        = 0;
            raf.receivedPower(cleanBurstRow,cleanBurstSlot(i)) = capture.sicResidual * raf.receivedPower(cleanBurstRow,cleanBurstSlot(i));

            if sum(raf.status(:,cleanBurstSlot(i))) == 0 % no capture scenario
                raf.slotStatus(cleanBurstSlot(i)) = 0;
            elseif sum(raf.status(:,cleanBurstSlot(i))) > 0 % capture scenario
                raf.slotStatus(cleanBurstSlot(i)) = 2;
            end
            % proceed with the interference cancelation
            twinPcktCol = raf.twins{ cleanBurstRow,cleanBurstSlot(i) };
            for twinPcktIdx = 1:length(twinPcktCol)
                raf.status(cleanBurstRow,twinPcktCol(twinPcktIdx)) = 0; % interference cancelation
                raf.receivedPower(cleanBurstRow,twinPcktCol(twinPcktIdx)) = capture.sicResidual * raf.receivedPower(cleanBurstRow,twinPcktCol(twinPcktIdx));
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
                    slotControl = find(cleanBurstSlot == twinPcktCol(twinPcktIdx));
                    if ~isempty(slotControl) && numel(slotControl) == 1
                        cleanBurstSlot(slotControl) = [];
                    elseif ~isempty(slotControl) && numel(slotControl) > 1
                        error('succede qualcosa di brutto');
                    end
                    newCleanBurstSlot = [newCleanBurstSlot,twinPcktCol(twinPcktIdx)];
                    raf.slotStatus(twinPcktCol(twinPcktIdx))  = 1;
                elseif sum(raf.status(:,twinPcktCol(twinPcktIdx))) > 1 && raf.slotStatus(twinPcktCol(twinPcktIdx)) ~= 1
                    % at least two bursts are colliding: do nothing, but notify that the SIR has changed
                    raf.slotStatus(twinPcktCol(twinPcktIdx)) = 2;
                end
            end
            i = i + 1;
        end
    end

    outRandomAccessFrame = raf;

elseif numel(newCleanBurstSlot) == 0

    % warning('Nothing to do here, exiting')
    outRandomAccessFrame = raf;
    ackedPcktsCol = [];
    ackedPcktsRow = [];

end