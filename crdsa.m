clear all;
% TODO: evolve from script to function [Issue: https://github.com/afcuttin/crdsa/issues/8]
source.number   = 14%200;
raf.length      = 10%100; % Casini et al., 2007, pag.1413
simulationTime  = 1000%10000; % total number of RAF
packetReadyProb = .5%0.3251;
capture.status  = 1;
capture.sirth   = 5;
capture.type    = 'ot';
maxIter         = 10;

% check for errors
% raf.length must be a positive integer greater than 1
validateattributes(raf.length,{'numeric'},{'scalar','integer','positive','>' 2},mfilename,'raf.length',2)
% source.number must be a positive integer greater than 2
validateattributes(source.number,{'numeric'},{'scalar','integer','positive','>' 2},mfilename,'source.number',1)
% simulationTime must be a positive integer
validateattributes(simulationTime,{'numeric'},{'scalar','integer','positive'},mfilename,'simulationTime',5)
% packet ready probability must be a double between 0 and 1
validateattributes(packetReadyProb,{'numeric'},{'scalar','real','>=', 0,'<=',1},mfilename,'packetReadyProb',3)

ackdPacketCount          = 0;
pcktTransmissionAttempts = 0;
pcktCollisionCount       = 0;
source.status            = zeros(1,source.number);
source.backoff           = zeros(1,source.number);
% legit source statuses are always non-negative integers and equal to:
% 0: source has no packet ready to be transmitted (is idle)
% 1: source has a packet ready to be transmitted, either because new data must be sent or a previously collided packet has waited the backoff time
% 2: source is backlogged due to previous packets collision
pcktGenerationTimestamp  = zeros(1,source.number);
currentRAF               = 0;

if ~exist('maxIter','var')
    warning('Performing complete interference cancellation.')
end

while currentRAF < simulationTime
    currentRAF = currentRAF + 1;

    raf.status     = zeros(source.number,raf.length); % memoryless
    raf.slotStatus = int8(zeros(1,raf.length));
    raf.twins      = cell(source.number,raf.length);
    changedSlots   = 0;

    % create the RAF
    for eachSource1 = 1:source.number
        if source.status(1,eachSource1) == 0 && rand(1) <= packetReadyProb % new packet
            source.status(1,eachSource1) = 1;
            % pcktGenerationTimestamp(1,eachSource1) = currentRAF; % necessario solo se si misura il ritardo
            [pcktTwins,rafRow]                = generateTwins(raf.length,2);
            raf.status(eachSource1,pcktTwins) = 1;
            raf.twins(eachSource1,:)          = rafRow;
        % elseif source.status(1,eachSource1) == 1 % backlogged source TODO: add a conditional to disable/enable retransmission of collided packets [Issue: https://github.com/afcuttin/crdsa/issues/7]
        %     firstReplicaSlot = randi(raf.length);
        %     secondReplicaSlot = randi(raf.length);
        %     while secondReplicaSlot == firstReplicaSlot
        %         secondReplicaSlot = randi(raf.length);
        %     end
        %     raf.status(eachSource1,firstReplicaSlot) = secondReplicaSlot;
        %     raf.status(eachSource1,secondReplicaSlot) = firstReplicaSlot;
        end
    end


    if capture.status == 1
        captureProbabilities = getCaptureProb(capture.sirth,capture.type);
        sizeOfCaptureProbabilities = numel(captureProbabilities);
        % slotSum = sum(sum(raf.status) == 1)
        % if slotSum > 0 % at least one clean burst exist
        %     raf.slotStatus    = int8(sum(raf.status) == 1);
        % elseif slotSum == 0 % all bursts collide, look for capture
        collisionSlots = find(sum(raf.status) > 1);
        for i = 1:numel(collisionSlots)
            burstsInSlot = nnz(raf.status(:,collisionSlots(i)));
            if burstsInSlot > 1 && burstsInSlot <= sizeOfCaptureProbabilities % otherwise the capture probability is equal to 0
                if rand(1) < captureProbabilities(burstsInSlot - 1)
                    raf.slotStatus(collisionSlots(i)) = 1;
                end
            % elseif burstsInSlot > 1 && burstsInSlot > sizeOfCaptureProbabilities
            %     if rand(1) < captureProbabilities(sizeOfCaptureProbabilities)
            %         raf.slotStatus(collisionSlots(i)) = 1;
            %     end
            end
        end
        % do not forget the possibly clean bursts
        raf.slotStatus = raf.slotStatus + int8(sum(raf.status) == 1);
        % end
        ackedCol = [];
        ackedRow = [];
        while sum(raf.slotStatus == 1) ~= 0

            [sicRaf,sicCol,sicRow] = sic(raf,maxIter);
            changedSlots = find(sicRaf.slotStatus == 2);
            for i = 1:numel(changedSlots)
                burstsInSlot = nnz(sicRaf.status(:,changedSlots(i)));
                if burstsInSlot == 0
                    % do nothing and clear the status
                    sicRaf.slotStatus(changedSlots(i)) = 0;
                elseif burstsInSlot == 1
                    % captured by default
                    sicRaf.slotStatus(changedSlots(i)) = 1;
                elseif burstsInSlot > 1 && burstsInSlot <= sizeOfCaptureProbabilities
                    if rand(1) < captureProbabilities(burstsInSlot - 1)
                        sicRaf.slotStatus(changedSlots(i)) = 1;
                    else
                        sicRaf.slotStatus(changedSlots(i)) = 0;
                    end
                elseif burstsInSlot > 1 && burstsInSlot > sizeOfCaptureProbabilities
                    % if rand(1) < captureProbabilities(sizeOfCaptureProbabilities)
                    %     sicRaf.slotStatus(changedSlots(i)) = 1;
                    % else
                        sicRaf.slotStatus(changedSlots(i)) = 0;
                    % end
                end
            end

            ackedCol = [ackedCol,sicCol];
            ackedRow = [ackedRow,sicRow];
            raf = sicRaf;
        end
        assert(numel(ackedRow) <= nnz(source.status),'The number of acknowledged bursts exceeds the number of sent bursts.')
    elseif ~exist('capture.status','var') || capture.status ~= 1 || capture.status == 0
        [sicRaf,ackedCol,ackedRow] = sic(raf,maxIter);
    end

    pcktTransmissionAttempts = pcktTransmissionAttempts + sum(source.status == 1); % "the normalized MAC load G does not take into account the replicas" Casini et al., 2007, pag.1411; "The performance parameter is throughput (measured in useful packets received per slot) vs. load (measured in useful packets transmitted per slot" Casini et al., 2007, pag.1415
    ackdPacketCount = ackdPacketCount + numel(ackedRow);

    % sourcesReady = find(source.status);
    % sourcesCollided = setdiff(sourcesReady,ackedRow);
    % if numel(sourcesCollided) > 0 % TODO: add a conditional to disable/enable retransmission of collided packets [Issue: https://github.com/afcuttin/crdsa/issues/10]
    %     pcktCollisionCount = pcktCollisionCount + numel(sourcesCollided);
    %     source.status(sourcesCollided) = 2;
    % end

    source.status = source.status - 1; % update sources statuses
    source.status(source.status < 0) = 0; % idle sources stay idle (see permitted statuses above)
end

loadNorm = pcktTransmissionAttempts / (simulationTime * raf.length)
throughputNorm = ackdPacketCount / (simulationTime * raf.length)
assert(throughputNorm <= loadNorm,'The throughput is greater than the load.')
pcktCollisionProb = pcktCollisionCount / (simulationTime * raf.length);
assert(pcktCollisionProb >= 0 && pcktCollisionProb <= 1,'The packet collision probability shall be a value between 0 and 1.')
packetLossRatio = 1 - ackdPacketCount / pcktTransmissionAttempts
