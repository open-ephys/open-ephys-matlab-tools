clear all; close all; clc;

s = Session('Data/BinarySyncTest');

s.recordNodes{1}.recordings{1}.addSyncChannel(1,105,0,1); %main sync 30kHz
s.recordNodes{1}.recordings{1}.addSyncChannel(1,105,1,0); %2.5kHz did not sync
s.recordNodes{1}.recordings{1}.addSyncChannel(1,105,2,0); %synced 30kHz
s.recordNodes{1}.recordings{1}.addSyncChannel(1,105,3,0); %2.5kHz did not sync
s.recordNodes{1}.recordings{1}.addSyncChannel(1,105,4,0); %synced 30kHz

s.recordNodes{1}.recordings{1}.computeGlobalTimestamps();

%Plot results

streams = s.recordNodes{1}.recordings{1}.continuous.keys;

figure;
for i = 1:length(streams)
    stream = s.recordNodes{1}.recordings{1}.continuous(streams{i});
    if 1 %mod(i,2)
        fprintf("Plotting stream: %d\n", i);
        plot(stream.globalTimestamps); hold on;
    end
    for j = 1:length(stream.globalTimestamps)
        fprintf('%f |', stream.globalTimestamps(j));
    end
    fprintf('\n');
end

