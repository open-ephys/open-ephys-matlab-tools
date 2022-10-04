# `open_ephys.control`

This module makes it possible to control the [Open Ephys GUI](https://open-ephys.org/gui) via Matlab, either running locally or over a network.

Your GUI's signal chain must include a [NetworkEvents](https://open-ephys.github.io/gui-docs/User-Manual/Plugins/Network-Events.html) plugin in order for this module to work.

To use the control module in Matlab:

- [Download ZeroMQ](https://zeromq.org/download/) for your specific platform
- Edit the paths to your zmq library file locations in control/matlab-zmq/config.m
- Run control/matlab-zmq/make.m to generate the required .mex files

Note: There are known issues when generating mex files for Matlab 2017+. It is possible to generate the mex files with an older version of Matlab and copy them to a newer version of Matlab. 

See this issue for more information:
https://github.com/fagg/matlab-zmq/issues/40#issuecomment-1030198530 

## Usage

### Initialization

To control a GUI instance running on the same machine, simply enter:

```matlab
gui = NetworkControl()
```

To specify a custom IP address or port number, use:

```matlab
gui = NetworkControl('10.127.50.1', 2000)
```

### Starting and stopping acquisition

To start acquisition, enter:

```matlab
gui.startAcquisition()
```

To stop acquisition, enter:

```matlab
gui.stopAcquisition()
```
    
To query acquisition status, use:

```matlab
gui.isAcquiring()
```

### Starting and stopping recording

To start recording, enter:

```matlab
gui.startRecording()
```

To stop recording while keeping acquisition active, enter:

```matlab
gui.stopRecording()
```
    
To query recording status, use:

```matlab
gui.isRecording()
```

### Sending TTL events

To send a TTL "ON" event, enter:

```matlab
gui.sendTTL(5, 1) %channel = 5, state = 1
```

To send a TTL "OFF" event, enter:

```matlab
gui.sendTTL(5, 0) %channel = 5, state = 0
```
