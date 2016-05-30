clear all;
% TODO: evolve from script to function [Issue: https://github.com/afcuttin/crdsa/issues/8]
source.number          = 200;
source.power           = ones(1,source.number);
raf.length             = 100; % Casini et al., 2007, pag.1413
simulationTime         = 2; % total number of RAF
packetReadyProb        = 0.3251;
capturePar.status      = 2;
% capturePar.sirth     = 5;
sicPar.maxIter         = 10;
sicPar.residual        = 0.1;
capturePar.threshold   = 3;
capturePar.sicResidual = sicPar.residual;
capturePar.criterion   = 'power';
capturePar.type        = 'basic';
cellRadius             = 10;
pathLoss.alpha         = 4;
pathLoss.model         = 1;

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

if ~isfield(sicPar,'maxIter')
    warning('Performing complete interference cancellation.')
end

while currentRAF < simulationTime
    currentRAF = currentRAF + 1;

    raf.status               = zeros(source.number,raf.length); % memoryless
    raf.slotStatus           = int8(zeros(1,raf.length));
    % raf.capturedSource       = zeros(1,raf.length); TODO: remove after testing [Issue: https://github.com/afcuttin/crdsa/issues/23]
    raf.receivedPower        = zeros(source.number,raf.length);
    raf.residualInterference = zeros(source.number,raf.length);
    raf.twins                = cell(source.number,raf.length);
    changedSlots             = 0;
    if capturePar.status ~= 0 % makes sense to generate an uniform surface distribution of sources
        source.rho   = cellRadius * sqrt(rand(1,source.number));
        source.theta = 2 * pi * rand(1,source.number);
    end

    % create the RAF
    for eachSource1 = 1:source.number
        if source.status(1,eachSource1) == 0 && rand(1) <= packetReadyProb % new packet
            source.status(1,eachSource1)             = 1;
            % pcktGenerationTimestamp(1,eachSource1) = currentRAF; % necessario solo se si misura il ritardo
            [pcktTwins,rafRow]                       = generateTwins(raf.length,2);
            raf.status(eachSource1,pcktTwins)        = 1;
            if capturePar.status ~= 0
                raf.receivedPower(eachSource1,pcktTwins) = source.power(eachSource1)./(pathLoss.model+source.rho(eachSource1).^pathLoss.alpha);
            end
            raf.twins(eachSource1,:)                 = rafRow;
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

    acked = [];

    switch capturePar.status
        case 0 % regular CRDSA
            [sicRaf,acked] = sic(raf,sicPar);
        case 1 % Iterative Capture Exploitation
            % captureProbabilities = getCaptureProb(capturePar.sirth,capturePar.type);
            % sizeOfCaptureProbabilities = numel(captureProbabilities);
            % collisionSlots = find(sum(raf.status) > 1);
            % for i = 1:numel(collisionSlots)
            %     burstsInSlot = nnz(raf.status(:,collisionSlots(i)));
            %     if burstsInSlot > 1 && burstsInSlot <= sizeOfCaptureProbabilities % otherwise the capture probability is equal to 0
            %         if rand(1) < captureProbabilities(burstsInSlot - 1)
            %             raf.slotStatus(collisionSlots(i)) = 1;
            %         end
            %     % elseif burstsInSlot > 1 && burstsInSlot > sizeOfCaptureProbabilities
            %     %     if rand(1) < captureProbabilities(sizeOfCaptureProbabilities)
            %     %         raf.slotStatus(collisionSlots(i)) = 1;
            %     %     end
            %     end
            % end
            % do not forget the possibly clean bursts
            raf.slotStatus = int8(sum(raf.status) == 1);
            enterTheLoop = true;

            while sum(raf.slotStatus == 1) ~= 0 || enterTheLoop
                % round of sic
                [sicRaf,sicCol,sicRow] = sic(raf,sicPar);
                % round of capture
                % changedSlots = find(sicRaf.slotStatus == 2);
                % if enterTheLoop == 1 && isempty(changedSlots)
                    %% only for the first iteration, if the SIC returns nothing, use the slots that have collisions
                    % changedSlots = find(sum(raf.status) > 1);
                % end
                for i = 1:numel(changedSlots)
                    burstsInSlot = nnz(sicRaf.status(:,changedSlots(i)));
                    if burstsInSlot == 0
                        % do nothing and clear the status
                        sicRaf.slotStatus(changedSlots(i)) = 0;
                    elseif burstsInSlot == 1
                        % captured by default
                        % sicRaf.capturedSource(changedSlots(i)) = find(sicRaf.status(:,changedSlots(i)));
                        % assert(numel(sicRaf.capturedSource(changedSlots(i))) == 1,'multiple bursts instead of only one');
                        sicRaf.slotStatus(changedSlots(i)) = 1;
                    elseif burstsInSlot > 1
                        captureAttempt = burstCapture(changedSlots(i),sicRaf,capturePar)
                        if captureAttempt > 0
                            sicRaf.slotStatus(changedSlots(i))     = 1;
                            % sicRaf.capturedSource(changedSlots(i)) = captureAttempt;
                        elseif captureAttempt == 0
                            sicRaf.slotStatus(changedSlots(i))     = 0;
                            % sicRaf.capturedSource(changedSlots(i)) = 0;
                        else
                            error('Something is wrong with burstCapture function');
                        end
                    end
                end

                acked.slot = [acked.slot,sicCol];
                acked.source = [acked.source,sicRow];
                raf = sicRaf;
                enterTheLoop = false;
            end
            assert(numel(acked.source) <= nnz(source.status),'The number of acknowledged bursts exceeds the number of sent bursts.')
        case 2 % sic + capture + sic
            % first round of sic
            [sicRaf,acked] = sic(raf,sicPar);
            % acked.slot        = [acked.slot,sicAcked.slot]; % TODO: remove after successful testing [Issue: https://github.com/afcuttin/crdsa/issues/21]
            % acked.source      = [acked.source,sicAcked.source]; % TODO: remove after successful testing [Issue: https://github.com/afcuttin/crdsa/issues/20]
            % round of capture
            [capRaf,capAcked] = capture(sicRaf,capturePar);
            acked.slot        = [acked.slot,capAcked.slot];
            acked.source      = [acked.source,capAcked.source];

            % TODO: delete the following lines after successful testing [Issue: https://github.com/afcuttin/crdsa/issues/22]
            % changedSlots = find(sicRaf.slotStatus == 2);
            % if enterTheLoop == 1 && isempty(changedSlots)
            %     % only for the first iteration, if the SIC returns nothing, use the slots that have collisions
            %     changedSlots = find(sum(raf.status) > 1);
            % end
            % for i = 1:numel(changedSlots)
            %     burstsInSlot = nnz(sicRaf.status(:,changedSlots(i)));
            %     if burstsInSlot == 0
            %         % do nothing and clear the status
            %         sicRaf.slotStatus(changedSlots(i)) = 0;
            %     elseif burstsInSlot == 1
            %         % captured by default
            %         % sicRaf.capturedSource(changedSlots(i)) = burstCapture(changedSlots(i),sicRaf,capturePar)
            %         sicRaf.slotStatus(changedSlots(i)) = 1;
            %     elseif burstsInSlot > 1
            %         captureAttempt = burstCapture(changedSlots(i),sicRaf,capturePar);
            %         if captureAttempt > 0
            %             sicRaf.slotStatus(changedSlots(i))     = 1;
            %             % sicRaf.capturedSource(changedSlots(i)) = captureAttempt;
            %         else
            %             sicRaf.slotStatus(changedSlots(i))     = 0;
            %             % sicRaf.capturedSource(changedSlots(i)) = 0;
            %         end
            %     end
            % end

            % second round of sic
            [sicRaf,sicAcked] = sic(capRaf,sicPar);
            acked.slot        = [acked.slot,sicAcked.slot];
            acked.source      = [acked.source,sicAcked.source];
    end

    pcktTransmissionAttempts = pcktTransmissionAttempts + sum(source.status == 1); % "the normalized MAC load G does not take into account the replicas" Casini et al., 2007, pag.1411; "The performance parameter is throughput (measured in useful packets received per slot) vs. load (measured in useful packets transmitted per slot" Casini et al., 2007, pag.1415
    ackdPacketCount = ackdPacketCount + numel(acked.source);

    % sourcesReady = find(source.status);
    % sourcesCollided = setdiff(sourcesReady,acked.source);
    % if numel(sourcesCollided) > 0 % TODO: add a conditional to disable/enable retransmission of collided packets [Issue: https://github.com/afcuttin/crdsa/issues/10]
    %     pcktCollisionCount = pcktCollisionCount + numel(sourcesCollided);
    %     source.status(sourcesCollided) = 2;
    % end

    source.status = source.status - 1; % update sources statuses
    source.status(source.status < 0) = 0; % idle sources stay idle (see permitted statuses above)
end

loadNorm       = pcktTransmissionAttempts / (simulationTime * raf.length)
throughputNorm = ackdPacketCount / (simulationTime * raf.length)
assert(throughputNorm <= loadNorm,'The throughput is greater than the load.')
pcktCollisionProb = pcktCollisionCount / (simulationTime * raf.length);
assert(pcktCollisionProb >= 0 && pcktCollisionProb <= 1,'The packet collision probability shall be a value between 0 and 1.')
packetLossRatio = 1 - ackdPacketCount / pcktTransmissionAttempts
