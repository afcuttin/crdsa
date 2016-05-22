function [capturedSource] = burstCapture(collisionSlotIndex,raf,capture)
% function [capturedSource] =  packetCapture(collisionSlotIndex,raf,capture)
% Evaluates the capture effect for colliding packets in a slotted Aloha-like environment.
%
% Returns 0 if no capture occurs.
% If capture occurs, returns the index of source.status corresponding to the source whose packet has been captured

collided = find(raf.status(:,collisionSlotIndex) == 1)
if numel(collided) == 1
	capturedSource = collided;
	fprintf('Warning: there are no collisions!\nNevertheless, I provide you with the right answer without computing the capture ratio.\n')
elseif numel(collided) > 1
	captured = find(raf.receivedPower(:,collisionSlotIndex) == max(raf.receivedPower(collided,collisionSlotIndex)))
	if ismember(captured,collided) % otherwise a packet that has been canceled can be caputured
		% TODO: il controllo della riga 14 dovrebbe essere sempre vero, quindi il condizionale va rimosso, insieme alle righe 23 - 26 [Issue: https://github.com/afcuttin/crdsa/issues/11]
		% captureRatio   = raf.receivedPower(captured,collisionSlotIndex) / sum(raf.receivedPower([1:end ~= captured],collisionSlotIndex));
		captureRatiodB = 10 * log10(raf.receivedPower(captured,collisionSlotIndex) / sum(raf.receivedPower([1:end ~= captured],collisionSlotIndex)))
		if captureRatiodB >= capture.threshold
			capturedSource = captured
		elseif captureRatiodB < capture.threshold
			capturedSource = 0
		end
	else
		error('captured burst is not a collided (valid) burst')
		capturedSource = 0;
	end
else
	error('you want me to do the capture in the %u rd slot, but there are %u slots here',collisionSlotIndex,collided);
end

