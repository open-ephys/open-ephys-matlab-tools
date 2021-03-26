# `open_ephys.analysis`

This module is intended for loading data saved by the [Open Ephys GUI](https://open-ephys.org/gui). It makes data accessible through a common interface, regardless of which format it's stored in.

To get started, simply run:

```matlab
directory = '/path/to/data/2020-11-10_09-28-30'; %for example

session = Session(directory)
```

This will create a `Session` object that holds information about your recording session. This includes all of the data that was saved in the specified directory, although the data won't be loaded into memory until it's requested.

## How recordings are organized

The Open Ephys GUI provides a great deal of flexibility when it comes to saving data. As of GUI version 0.5+, data is saved by any Record Nodes that have been inserted into the signal chain. This makes is possible to record both the raw data as well as data that has been transformed by different processing stages. By default, all Record Nodes will save data to the same directory, in sub-folders named "Record Node <ID>," where <ID> is the Record Node's processor ID. Each Record Node can store data in a different format, although the [Binary format](https://open-ephys.github.io/gui-docs/User-Manual/Recording-data/Binary-format.html) is the default format that is recommended for most use cases.

To access the data for the first Record Node, enter:

```matlab
node = session.recordNodes{1} 
```

If data from multiple Record Nodes is stored in the same directory, you can use the `show` function to view information about the Record Nodes in the `Session` object, e.g.:

```text
>> session.show()

(1) Record Node 118 : Binary Format 
(2) Record Node 119 : OpenEphys Format 
(3) Record Node 120 : KWIK Format 
(4) Record Node 121 : NWB Format
```

Within each Record Node, recordings are grouped by "experiments" and "recordings." A new "experiment" begins whenever data acquisition is stopped and re-started, as this re-sets the incoming hardware timestamps to zero. Within a given experiment, all of the timestamps are relative to a common start time. Starting and stopped recording (but not acquisition) in the GUI will initiate a new "recording." Each recording will have contiguous timestamps that increment by 1 for each sample.

The `analysis` module does not have a separate hierarchical level for experiments. Instead, each recording (regardless of the experiment index) is accessed through the `session.recordNodes{N}.recordings` list.

## Loading continuous data

Continuous data for each recording is accessed via the `.continuous` property of each `Recording` object. This returns a list of continuous data, grouped by processor/sub-processor. For example, if you have two data streams merged into a single Record Node, each data stream will be associated with a different processor ID. If you're recording Neuropixels data, each probe's data stream will be stored in a separate sub-processor, which must be loaded individually.

Each `continuous` object has three properties:

- `samples` - an `array` that holds the actual continuous data with dimensions of samples x channels. For Binary, NWB, and Kwik format, this will be a memory-mapped array (i.e., the data will only be loaded into memory when specific samples are accessed)
- `timestamps` - an `array` that holds the sample indices. This will have the same size as the first dimension of the `samples` array
- `metadata` - a `struct` containing information about this data, such as the ID of the processor it originated from.


## Loading event data

Event data for each recording is accessed via the `.events` property of each `Recording` object. This returns a pandas DataFrame with the following columns:

- `timestamp` - the sample index at which this event occurred
- `channel` - the channel on which this event occurred
- `nodeId` - the ID of the processor from which this event originated
- `state` - 1 or 0, to indicate whether this is a rising edge or falling edge event


## Loading spike data

If spike data has been saved by your Record Node (i.e., there is a Spike Detector or Spike Sorter upstream in the signal chain), this can be accessed via the `.spikes` property of each `Recording` object. This returns a list of spike sources, each of which has the following properties:

- `waveforms` - `array` containing spike waveforms, with dimensions of spikes x channels x samples
- `timestamps` - `array` of sample indices (one per spikes)
- `electrodes` - `array` containing the index of the electrode from which each spike originated
- `metadata` - `struct` with metadata about each electrode


