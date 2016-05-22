function [outRandomAccessFrame,ackedBursts] = capture(raf,capture)
% function [outputRandomAccessFrame,ackedPcktsCol,ackedPcktsRow] = capture(inputRandomAccessFrame,,capture)
% TODO: update capture function help [Issue: https://github.com/afcuttin/crdsa/issues/13]
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

ackedBursts.slot   = [];
ackedBursts.source = [];

if capture.type == 'basic'
    collidedSlots = find(sum(raf.status) > 1);
elseif capture.type == 'advanced'
    collidedSlots = find(raf.slotStatus == 2);
else
    warning('Please specify the capture type: basic or advanced. Otherwise basic will be used.');
    collidedSlots = find(sum(raf.status) > 1);
end

for i = 1:numel(collidedSlots)
    burstsInSlot = nnz(raf.status(:,collidedSlots(i)));
    if burstsInSlot > 1
        switch capture.criterion
            case 'power'
                capturedSource = burstCapture(collidedSlots(i),raf,capture)
            case 'time'
                % TODO: develop capture by jitter [Issue: https://github.com/afcuttin/crdsa/issues/14]
            case 'frequency'
                % TODO: develop capture by frequency offset [Issue: https://github.com/afcuttin/crdsa/issues/12]
            case 'otherTypeOfReceiver'
                % placeholder for another type of receiver
            otherwise
                error('Please specify the capture criterion: power, or time, or frequency');
         end
        if capturedSource > 0
            % update the list of acked bursts
            ackedBursts.slot   = [ackedBursts.slot,collidedSlots(i)];
            ackedBursts.source = [ackedBursts.source,capturedSource];
            % update the raf
            raf.status(capturedSource,collidedSlots(i))        = 0;
            raf.receivedPower(capturedSource,collidedSlots(i)) = capture.sicResidual * raf.receivedPower(capturedSource,collidedSlots(i));
            % sir has changed, update the slot status
            raf.slotStatus(collidedSlots(i)) = 2;
            % cancel the twin(s)
            twinBurstSlot = raf.twins{ capturedSource,collidedSlots(i) };
            for twinBurstIdx = 1:length(twinBurstSlot)
                raf.status(capturedSource,twinBurstSlot(twinBurstIdx))        = 0;
                raf.receivedPower(capturedSource,twinBurstSlot(twinBurstIdx)) = capture.sicResidual * raf.receivedPower(capturedSource,twinBurstSlot(twinBurstIdx));
                % sir has changed, update the slot status
                raf.slotStatus(twinBurstSlot(twinBurstIdx)) = 2;
            end
        elseif capturedSource == 0
            raf.slotStatus(collidedSlots(i)) = 0;
        else
            error('Something is wrong with burstCapture function, its value is %u',capturedSource);
        end
    else
        error('Something is wrong with the capture: there are %u burst in this slot',burstsInSlot);
    end
end

outRandomAccessFrame = raf;
