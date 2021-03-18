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

To use the control module:
- Install the zmq libraries for your specific platform
- Edit the paths to your zmq library file locations in control/matlab-zmq/config.m
- Run control/matlab-zmq/make.m to generate the required .mex files

## Usage

### analysis

```
path = 'SampleData/BinaryFormat/Record Node 118';
experimentIdx = 1;
recordingIdx = 1;

recording = BinaryRecording(path, experimentIdx, recordingIdx);

streams = recording.continuous.keys;

NeuropixelsData = recording.continuous(streams{1});
NIDAQData = recording.continuous(streams{2});

%Plot the first 30000 samples on all channels
sampleRange = 1:30000 
plot(NeuropixelsData.samples(:,sampleRange)); 
```

### control

```
control = NetworkControl()

control.startAcquisition();
control.startRecording();

control.isRecording(); %returns true

control.stopRecording();

control.isRecording(); %returns false

control.stopAcquisition();
```

### streaming

(coming soon)

## Contributing

This code base is under active development, and we welcome bug reports, feature requests, and external contributions. If you're working on an extension that you think would be useful to the community, don't hesitate to [submit an issue](https://github.com/open-ephys/open-ephys-python-tools/issues).