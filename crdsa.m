clear all;

sourceNumber = 15;
randomAccessFrameLength = 15;
simulationTime = 1; % total number of RAF
packetReadyProb = .5;
maxBackoff = 5;

sourceStatus = zeros(1,sourceNumber);
% legit source statuses are always non-negative integers and equal to:
% 0: source has no packet ready to be transmitted (is idle)
% 1: source has a packet ready to be transmitted, either because new data must be sent or a previously collided packet has waited the backoff time
% >1: source is backlogged due to previous packets collision, the value of the status equals the number of slots it must wait for the next transmission attempt
randomAccessFrame = zeros(sourceNumber,randomAccessFrameLength);
randomAccessFrameLog = zeros(sourceNumber,randomAccessFrameLength);
% later on referred to as RAF: Random Access Frame
currentRAF = 0;

while currentRAF < simulationTime
    currentRAF = currentRAF + 1;

    for eachSource1 = 1:sourceNumber
        if sourceStatus(1,eachSource1) == 0 && rand(1) <= packetReadyProb % new packet
            sourceStatus(1,eachSource1) = 1;
            sourceBackoff(1,eachSource1) = randi(maxBackoff,1);
            pcktGenerationTimestamp(1,eachSource1) = currentRAF;

            firstReplicaSlot = randi(randomAccessFrameLength)
            secondReplicaSlot = randi(randomAccessFrameLength)
            while secondReplicaSlot == firstReplicaSlot
            	secondReplicaSlot = randi(randomAccessFrameLength)
        	end
            randomAccessFrame(eachSource1,firstReplicaSlot) = secondReplicaSlot;
            randomAccessFrame(eachSource1,secondReplicaSlot) = firstReplicaSlot;

        elseif sourceStatus(1,eachSource1) == 1 % backlogged packet
            sourceBackoff(1,eachSource1) = randi(maxBackoff,1);
        end
    end
    randomAccessFrame

    acked_col=find(sum(randomAccessFrame>0)==1) % find column indexes of packets without collisions
    
    [row_c,col_c,twinSlotId] = find(randomAccessFrame);
        row=transpose(row_c);
    col=transpose(col_c);
    [~,col_ind]=ismember(acked_col,col);

    acked_row = row(col_ind)

% now let's do the successive interference cancellation
ackedPacketIdx = 1;
while ackedPacketIdx < numel(acked_col)

    twinCol = randomAccessFrame(acked_row(ackedPacketIdx),acked_col(ackedPacketIdx)) % get twin packet slot id
    randomAccessFrame % only for debug
    acked_col % only for debug
    acked_row % only for debug

    if sum(randomAccessFrame(:,twinCol)>0) > 1 % twin packet has collided
        randomAccessFrame(acked_row(ackedPacketIdx),twinCol) = 0 % cancel twin packet, thus reducing potential interference
        if sum(randomAccessFrame(:,twinCol)>0) == 1 % check if a new package can be acknowledged, thanks to interference cancellation
            acked_col(numel(acked_col) + 1) = twinCol
            acked_row(numel(acked_row) + 1) = find(randomAccessFrame(:,twinCol))
        end
    elseif sum(randomAccessFrame(:,twinCol)>0) == 1 % twin packet has not collided, so let's remove its column index from the acked packets arrays
        twinAckedInd = find(acked_col == twinCol)
        acked_col(twinAckedInd) = []
        acked_row(twinAckedInd) = []
    end

    pause % only for debug

    ackedPacketIdx = ackedPacketIdx + 1
end    


    

    % pcktTransmissionAttempts = pcktTransmissionAttempts + sum(sourceStatus == 1);

    % if sum(sourceStatus == 1) == 1
    %     ackdPacketCount = ackdPacketCount + 1;
    %     [~,sourceId] = find(sourceStatus == 1);
    %     ackdPacketDelay(ackdPacketCount) = currentRAF - pcktGenerationTimestamp(sourceId);
    % elseif sum(s ou rceStatus == 1) > 1
    %     pcktCollisionCount = pcktCollisionCount + 1;
    %     sourceStatus  = sourceStatus + sourceBackoff;
    % end

    % sourceStatus = sourceStatus - 1; % decrease backoff interval
    % sourceStatus(sourceStatus < 0) = 0; % idle sources stay idle (see permitted statuses above)
    % sourceBackoff = zeros(1,sourceNumber);
end
