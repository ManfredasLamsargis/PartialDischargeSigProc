scriptDir = fileparts(mfilename('fullpath'));

psFilePath = fullfile(scriptDir, '..//..//Data//20260528_1c_EFZ_2c_50Hz_3_logo50_32kV_antDOBB.mat');
if ~isfile(psFilePath)
    error('expected picoscope oscilloscope datafile not found %s', psFile);
end

psFile = load(psFilePath);

sampleCount = double(psFile.Length);
timeStamps = (0:sampleCount-1)' * psFile.Tinterval + double(psFile.Tstart);

decimalFactor = 1000;
index = 1:decimalFactor:sampleCount;

figure('Name', 'Channel A', 'NumberTitle', 'off');
plot(timeStamps(index), psFile.A(index), 'Color', 'b');
xlabel('Time (s)');
ylabel('Voltage');
title('Channel A decimated view');
grid on;

figure('Name', 'Channel B', 'NumberTitle', 'off');
plot(timeStamps(index), psFile.B(index), 'Color', 'r');
xlabel('Time (s)');
ylabel('Voltage');
title('Channel B decimated view');
grid on;

figure('Name', 'Channel C', 'NumberTitle', 'off');
plot(timeStamps(index), psFile.C(index), 'Color', '#006400');
xlabel('Time (s)');
ylabel('Voltage');
title('Channel C decimated view');
grid on;
