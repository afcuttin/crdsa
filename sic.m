function [outRandomAccessFrame,ackedBursts] = sic(raf,sicParameters)
% function [outRandomAccessFrame,ackedBursts] = sic(raf,sicParameters)
%
% perform Successive Interference Cancellation (SIC) on a given Random Access Frame for Contention Resolution Diversity Slotted Aloha
%
% Input parameters
%   - raf:     the structure of matrices containing slots and bursts informations
%   - maxIter: the maximum number of times the Successive Interference Cancelation can be performed TODO: change the description of the second argument of the function [Issue: https://github.com/afcuttin/crdsa/issues/19]
%
% Output parameters
%   - outRandomAccessFrame: the structure of matrices containing slots and bursts informations, after SIC
%   - ackedBursts.slot:     an array containing the column (slots) indices of acknowledged bursts after SIC
%   - ackedBursts.source:   an array containing the row (sources) indices of acknowledged bursts after SIC

if ~isfield(sicParameters,'maxIter')
    % perform complete interference cancelation, maxIter is set equal to the number of active sources
    sicParameters.maxIter = nnz(sum(raf.status,2));
end

iterCounter        = 0;
ackedBursts.slot   = [];
ackedBursts.source = [];
newCleanBurstSlot  = find(sum(raf.status) == 1);

% TODO: evaluate if the clean bursts can be captured (that is, correctly received) (put a for cycle that evaluates the burstCapture function for every slot) [Issue: https://github.com/afcuttin/crdsa/issues/24]

if numel(newCleanBurstSlot) > 0
    raf.slotStatus(newCleanBurstSlot) = 1;
    while sum(raf.slotStatus == 1) ~= 0 && iterCounter <= sicParameters.maxIter

        iterCounter       = iterCounter + 1;
        cleanBurstSlot    = newCleanBurstSlot;
        newCleanBurstSlot = [];

        ii = 1;
        while ii <= numel(cleanBurstSlot)
            cleanBurstRow = find(raf.status(:,cleanBurstSlot(ii)));
            assert(numel(cleanBurstRow) == 1,'ci sono %u burst in questo slot, invece di uno soltanto',numel(cleanBurstRow)); % TODO: remove this line after testing [Issue: https://github.com/afcuttin/crdsa/issues/17]
            % update the list of acked bursts
            ackedBursts.slot   = [ackedBursts.slot,cleanBurstSlot(ii)];
            ackedBursts.source = [ackedBursts.source,cleanBurstRow];
            % update raf
            raf.status(cleanBurstRow,cleanBurstSlot(ii))        = 0;
            raf.receivedPower(cleanBurstRow,cleanBurstSlot(ii)) = sicParameters.residual * raf.receivedPower(cleanBurstRow,cleanBurstSlot(ii)); % TODO: per il pacchetto ricevuto correttamente non serve cambiare la potenza ricevuta [Issue: https://github.com/afcuttin/crdsa/issues/18]
            % update slot status
            raf.slotStatus(cleanBurstSlot(ii))           = 0;
            % proceed with the interference cancelation
            twinPcktCol = raf.twins{ cleanBurstRow,cleanBurstSlot(ii) };
            for twinPcktIdx = 1:length(twinPcktCol)
                raf.status(cleanBurstRow,twinPcktCol(twinPcktIdx))        = 0; % interference cancelation
                raf.receivedPower(cleanBurstRow,twinPcktCol(twinPcktIdx)) = sicParameters.residual * raf.receivedPower(cleanBurstRow,twinPcktCol(twinPcktIdx));
                if sum(raf.status(:,twinPcktCol(twinPcktIdx))) == 0 % twin burst was a clean burst
                    nonCollTwinInd = find(cleanBurstSlot == twinPcktCol(twinPcktIdx));
                    if ~isempty(nonCollTwinInd)
                        cleanBurstSlot(nonCollTwinInd) = []; %remove the twin burst from the acked bursts list
                    end
                    nonCollTwinInd = find(newCleanBurstSlot == twinPcktCol(twinPcktIdx));
                    if ~isempty(nonCollTwinInd)
                        newCleanBurstSlot(nonCollTwinInd) = []; %remove the twin burst from the acked bursts list
                    end
                    raf.slotStatus(twinPcktCol(twinPcktIdx)) = 0;
                elseif sum(raf.status(:,twinPcktCol(twinPcktIdx))) == 1 % a new burst is clean, thanks to interference cancellation
                    % TODO check if the new clean burst can be captured
                    newCleanBurstSlot                        = [newCleanBurstSlot,twinPcktCol(twinPcktIdx)];
                    raf.slotStatus(twinPcktCol(twinPcktIdx)) = 1;
                elseif sum(raf.status(:,twinPcktCol(twinPcktIdx))) > 1 % at least two bursts are colliding, but the sir has changed
                    raf.slotStatus(twinPcktCol(twinPcktIdx)) = 2;
                end
            end
            ii = ii + 1;
        end
    end

    outRandomAccessFrame = raf;

elseif numel(newCleanBurstSlot) == 0
    % warning('Nothing to do here, exiting')
    outRandomAccessFrame = raf;
end
