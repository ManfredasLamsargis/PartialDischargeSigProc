# Partial Discharge Signal Processing
## Setup
### Dataset
Download needed `.psdata` file and install [Picoscope 7](https://www.picotech.com/products/picoscope-7-software). Open the `.psdata` file and save as MATLAB file in project's `Data` folder. The file of the same name with `.mat` file extention will appear in the `Data` folder.
### Python ML
#### Debian-based
```bash
sudo apt install python3 python3-venv python-is-python3 -y
```
Create virtual environment in `Python` folder:
```bash
cd Source/Python
python -m venv .venv
source .venv/bin/activate
pip install numpy matplotlib scipy
python plot_chan_a.py
```
If you get a plotting error in:
```bash
PartialDischargeSigProc/Source/Python/plot_chan_a.py:26: UserWarning: FigureCanvasAgg is non-interactive, and thus cannot be shown
  plt.show()
```
On Plasma KDE install PyQt:
```bash
pip install PyQt6
```
