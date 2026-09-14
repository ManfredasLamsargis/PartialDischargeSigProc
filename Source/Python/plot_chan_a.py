import os
import numpy as np
import matplotlib.pyplot as plt
from scipy.io import loadmat

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    ps_file_path = os.path.join(script_dir, "../..", "Data", "20260528_1c_EFZ_2c_50Hz_3_logo50_32kV_antDOBB.mat")
    data = loadmat(ps_file_path)

    length = int(np.squeeze(data["Length"]))
    tinterval = float(np.squeeze(data["Tinterval"]))
    tstart = float(np.squeeze(data["Tstart"]))
    channel_a = np.squeeze(data["A"])

    time_stamps = np.arange(length) * tinterval + tstart
    decimal_factor = 1000
    index = slice(0, length, decimal_factor)

    plt.figure(figsize=(14, 6))
    plt.plot(time_stamps[index], channel_a[index], color="b")
    plt.xlabel("Time (s)")
    plt.ylabel("Voltage")
    plt.title("Channel A decimated view")
    plt.grid(True)
    plt.show()

if __name__ == "__main__":
    main()
