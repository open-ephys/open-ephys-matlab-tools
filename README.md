# Open Ephys Matlab Tools

<img src="logo.png" width="300" />

## Overview

This repository is meant to centralize and standardize Matlab-specific tools for interacting with the [Open Ephys GUI](https://github.com/open-ephys/plugin-GUI).

It consists of three modules:

1. `analysis` - loads data in every format supported by the GUI, using a common interface

2. `control` - allows a Matlab process to control the GUI, locally or over a network connection

3. `streaming` - (under development) receives data from the GUI for real-time analysis and visualization in Matlab

## Installation

All scripts and classes are available in the open-ephys directory. Make sure the open-ephys directory and the data to be analyzed are both on the Matlab search path.

See the [control module README file](open_ephys/control/README.md) for how to setup zmq with Matlab.

## Usage

### analysis

```matlab
directory = '/path/to/data/2020-11-10_09-28-30' % for example

session = Session(directory) 
```

If the directory contains data from one more Record Nodes (GUI version 0.5+), the `session` object will contain a list of RecordNodes, accessible via `session.recordNodes[N]`, where `N = 1, 2, 3,`, etc.  

If your directory just contains data (any GUI version), individual recordings can be accessed via `session.recordings`. The format of the recordings will be detected automatically as either 
[Binary](https://open-ephys.github.io/gui-docs/User-Manual/Recording-data/Binary-format.html), 
[Open Ephys](https://open-ephys.github.io/gui-docs/User-Manual/Recording-data/Binary-format.html), 
[NWB 1.0](https://open-ephys.github.io/gui-docs/User-Manual/Recording-data/NWB-format.html), or 
[KWIK](https://open-ephys.github.io/gui-docs/User-Manual/Recording-data/KWIK-format.html).

Each `recording` object has the following fields:

* `continuous` : continuous data for each subprocessor in the recording
* `spikes` : spikes for each electrode group
* `events` : Pandas `DataFrame` Matlab analog of event times and metadata

More details about `continuous`, `spikes`, and `events` objects can be found in the [analysis module README file](open_ephys/analysis/README.md).

### control

```matlab
url = '10.128.50.10' % IP address of the computer running Open Ephys 
port = 2000 

gui = NetworkControl(url, port)

gui.startAcquisition %starts acquisition
```

### streaming

(coming soon)

## Contributing

This code base is under active development, and we welcome bug reports, feature requests, and external contributions. If you're working on an extension that you think would be useful to the community, don't hesitate to [submit an issue](https://github.com/open-ephys/open-ephys-matlab-tools/issues).