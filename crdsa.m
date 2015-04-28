clear all;

sourceNumber = 10;
randomAccessFrameLength = 15;
simulationTime = 1; % total number of RAF
packetReadyProb = 1;
maxBackoff = 5;

sourceStatus = zeros(1,sourceNumber);
% legit source statuses are always non-negative integers and equal to:
% 0: source has no packet ready to be transmitted (is idle)
% 1: source has a packet ready to be transmitted, either because new data must be sent or a previously collided packet has waited the backoff time
% >1: source is backlogged due to previous packets collision, the value of the status equals the number of slots it must wait for the next transmission attempt
randomAccessFrame = zeros(sourceNumber,randomAccessFrameLength); % later on referred to as RAF
% randomAccessFrameLog = zeros(sourceNumber,randomAccessFrameLength);

currentRAF = 0;
while currentRAF < simulationTime
    currentRAF = currentRAF + 1;

    for eachSource1 = 1:sourceNumber % create the RAF
        if sourceStatus(1,eachSource1) == 0 && rand(1) <= packetReadyProb % new packet
            sourceStatus(1,eachSource1) = 1;
            sourceBackoff(1,eachSource1) = randi(maxBackoff,1);
            pcktGenerationTimestamp(1,eachSource1) = currentRAF;

            firstReplicaSlot = randi(randomAccessFrameLength);
            secondReplicaSlot = randi(randomAccessFrameLength);
            while secondReplicaSlot == firstReplicaSlot
            	secondReplicaSlot = randi(randomAccessFrameLength);
        	end
            randomAccessFrame(eachSource1,firstReplicaSlot) = secondReplicaSlot;
            randomAccessFrame(eachSource1,secondReplicaSlot) = firstReplicaSlot;
        elseif sourceStatus(1,eachSource1) == 1 % backlogged packet
            sourceBackoff(1,eachSource1) = randi(maxBackoff,1);
        end
    end

    acked_col=find(sum(randomAccessFrame>0)==1); % find column indices of packets without collisions
    [row_c,col_c,twinSlotId] = find(randomAccessFrame);
    row=transpose(row_c);
    col=transpose(col_c);
    [~,col_ind]=ismember(acked_col,col);
    acked_row = row(col_ind); % find row indices of packets without collisions

    [sicRAF,sicCol,sicRow] = sic(randomAccessFrame,acked_col,acked_row); % do the Successive Interference Cancellation

sicRAF
sicCol
sicRow

    pcktTransmissionAttempts = pcktTransmissionAttempts + sum(sourceStatus == 1);
    ackdPacketCount = ackdPacketCount + numel(sicCol);
    % if sum(sourceStatus == 1) == 1
    if numel(sicCol) > 0

    %     [~,sourceId] = find(sourceStatus == 1);
    %     ackdPacketDelay(ackdPacketCount) = currentRAF - pcktGenerationTimestamp(sourceId);
    % elseif sum(sourceStatus == 1) > 1
    %     pcktCollisionCount = pcktCollisionCount + 1;
    %     sourceStatus  = sourceStatus + sourceBackoff;
    % end

    % sourceStatus = sourceStatus - 1; % decrease backoff interval
    % sourceStatus(sourceStatus < 0) = 0; % idle sources stay idle (see permitted statuses above)
    % sourceBackoff = zeros(1,sourceNumber);
end
