clear all;
% TODO: evolve from script to function [Issue: https://github.com/afcuttin/crdsa/issues/8]
source.number   = 200;
raf.length      = 100; % Casini et al., 2007, pag.1413
simulationTime  = 5000; % total number of RAF
packetReadyProb = 0.3251;
capture.status  = 0;
maxIter = 100;

% check for errors
% TODO: check variable value - raf.length must be a positive integer and greater than 1 [Issue: https://github.com/afcuttin/crdsa/issues/4]
% TODO: check variable value - source.number must be a positive integer [Issue: https://github.com/afcuttin/crdsa/issues/1]
% TODO: check variable value - simulationTime must be a positive integer [Issue: https://github.com/afcuttin/crdsa/issues/2]
% TODO: check variable value - packet ready probability must be a double between 0 and 1 [Issue: https://github.com/afcuttin/crdsa/issues/5]

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
    raf.slotStatus = zeros(raf.length);
    raf.twins      = cell(source.number,raf.length);

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

        raf.slotStatus = sum(raf.status) >= 1 % initialize with slots where there are clean bursts or collided bursts

        collisionSlots = find(sum(raf.status > 0) > 1);
        counter = 1;
        doCapturablePacketsExist = 0;
        doCollisionsExist = numel(collisionSlots);
        % check if at least one burst can be captured, in order to switch between the following cases
        if doCollisionsExist > 0 % && numel(nonCollPcktsCol) == 0
            while doCapturablePacketsExist == 0 && counter <= doCollisionsExist
                capturedSource = packetCapture(collisionSlots(counter),raf,capture);
                if capturedSource > 0
                    doCapturablePacketsExist = 1
                elseif capturedSource == 0
                    counter = counter + 1
                end
            end
        end

    elseif ~exist('capture.status') || capture.status ~= 1 || capture.status == 0
        [sicRAF,sicCol,sicRow] = sic(raf,maxIter);
    end

    pcktTransmissionAttempts = pcktTransmissionAttempts + sum(source.status == 1); % "the normalized MAC load G does not take into account the replicas" Casini et al., 2007, pag.1411; "The performance parameter is throughput (measured in useful packets received per slot) vs. load (measured in useful packets transmitted per slot" Casini et al., 2007, pag.1415
    ackdPacketCount = ackdPacketCount + numel(sicCol);

    sourcesReady = find(source.status);
    sourcesCollided = setdiff(sourcesReady,sicRow);
    % if numel(sourcesCollided) > 0 % TODO: add a conditional to disable/enable retransmission of collided packets [Issue: https://github.com/afcuttin/crdsa/issues/10]
    %     pcktCollisionCount = pcktCollisionCount + numel(sourcesCollided);
    %     source.status(sourcesCollided) = 2;
    % end

    source.status = source.status - 1; % update sources statuses
    source.status(source.status < 0) = 0; % idle sources stay idle (see permitted statuses above)
end

loadNorm = pcktTransmissionAttempts / (simulationTime * raf.length)
throughputNorm = ackdPacketCount / (simulationTime * raf.length)
pcktCollisionProb = pcktCollisionCount / (simulationTime * raf.length);
packetLossRatio = 1 - ackdPacketCount / pcktTransmissionAttempts
