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

%% Fourier transform (FFT) of each channel
Fs = 1 / psFile.Tinterval;      % sampling frequency, Hz
N  = sampleCount;                % number of samples used for FFT

fprintf('Fs = %.3f Hz, Nyquist = %.3f Hz, N = %d samples\n', Fs, Fs/2, N);

% Frequency axis (single-sided)
f = Fs * (0:floor(N/2)) / N;

channels = {'A', 'B', 'C'};
colors   = {'b', 'r', '#006400'};

for k = 1:numel(channels)
    chName = channels{k};
    sig = double(psFile.(chName));

    % Sanity check: any NaN/Inf will silently break fft/plot
    if any(~isfinite(sig))
        warning('Channel %s contains NaN/Inf values — cleaning before FFT.', chName);
        sig(~isfinite(sig)) = 0;
    end

    % Remove DC offset before transforming
    sig = sig - mean(sig);

    Y = fft(sig);
    P2 = abs(Y / N);
    P1 = P2(1:floor(N/2)+1);
    P1(2:end-1) = 2 * P1(2:end-1);

    fprintf('Channel %s: max amplitude = %.6g at %.3f Hz\n', ...
        chName, max(P1), f(P1 == max(P1)));

    figure('Name', ['Channel ', chName, ' FFT'], 'NumberTitle', 'off');
    semilogy(f, P1, 'Color', colors{k});   % log scale reveals small components
    xlabel('Frequency (Hz)');
    ylabel('|Amplitude| (log scale)');
    title(['Channel ', chName, ' single-sided amplitude spectrum']);
    xlim([0, min(Fs/2, 1e5)]);   % ADJUST this upper limit to your signal band of interest
    grid on;
end

%% Short-Time Fourier Transform (STFT) / spectrogram of each channel
% Window length: pick something short enough to resolve fast transients
% but long enough for decent frequency resolution. Tune windowLenSec to taste.
windowLenSec = 0.001;                       % 1 ms window — ADJUST for your event timescale
windowLen    = round(windowLenSec * Fs);
windowLen    = max(windowLen, 8);           % sane floor
overlapLen   = round(0.5 * windowLen);      % 50% overlap
nfft         = max(256, 2^nextpow2(windowLen));

% Cap the displayed frequency range same as the FFT plots above
stftFreqLimHz = min(Fs/2, 1e5);             % ADJUST to match your band of interest

fprintf('STFT window = %d samples (%.3g s), overlap = %d samples, nfft = %d\n', ...
    windowLen, windowLen / Fs, overlapLen, nfft);

for k = 1:numel(channels)
    chName = channels{k};
    sig = double(psFile.(chName));

    if any(~isfinite(sig))
        sig(~isfinite(sig)) = 0;
    end
    sig = sig - mean(sig);

    figure('Name', ['Channel ', chName, ' STFT'], 'NumberTitle', 'off');
    [S, F, T] = spectrogram(sig, hamming(windowLen), overlapLen, nfft, Fs);

    % Shift T so it aligns with the file's actual start time (Tstart offset)
    T = T + double(psFile.Tstart);

    imagesc(T, F, 20*log10(abs(S) + eps));  % dB scale, avoids log(0)
    axis xy;                                 % low frequencies at bottom
    ylim([0, stftFreqLimHz]);
    colormap(jet);
    cb = colorbar;
    cb.Label.String = 'Magnitude (dB)';
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title(['Channel ', chName, ' STFT (spectrogram)']);
end

%% Magnitude-squared coherence between channel pairs
% Coherence estimates how linearly related two signals are as a function
% of frequency (0 = unrelated, 1 = perfectly linearly related at that freq).
% Uses Welch's method internally (same windowing logic as the STFT above).

cohWindowLenSec = 0.01;                         % 10 ms window — ADJUST as needed
cohWindowLen    = round(cohWindowLenSec * Fs);
cohWindowLen    = max(cohWindowLen, 8);
cohOverlapLen   = round(0.5 * cohWindowLen);    % 50% overlap
cohNfft         = max(256, 2^nextpow2(cohWindowLen));

cohFreqLimHz = min(Fs/2, 1e5);                  % same display cap as above

pairs = {'A','B'; 'A','C'; 'B','C'};

fprintf('Coherence window = %d samples (%.3g s), overlap = %d samples, nfft = %d\n', ...
    cohWindowLen, cohWindowLen / Fs, cohOverlapLen, cohNfft);

for p = 1:size(pairs, 1)
    ch1 = pairs{p, 1};
    ch2 = pairs{p, 2};

    sig1 = double(psFile.(ch1));
    sig2 = double(psFile.(ch2));

    if any(~isfinite(sig1)); sig1(~isfinite(sig1)) = 0; end
    if any(~isfinite(sig2)); sig2(~isfinite(sig2)) = 0; end

    sig1 = sig1 - mean(sig1);
    sig2 = sig2 - mean(sig2);

    [Cxy, fCoh] = mscohere(sig1, sig2, hamming(cohWindowLen), cohOverlapLen, cohNfft, Fs);

    figure('Name', ['Coherence ', ch1, '-', ch2], 'NumberTitle', 'off');
    plot(fCoh, Cxy, 'Color', 'k');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude-squared coherence');
    title(['Coherence between Channel ', ch1, ' and Channel ', ch2]);
    xlim([0, cohFreqLimHz]);
    ylim([0, 1]);
    grid on;
end