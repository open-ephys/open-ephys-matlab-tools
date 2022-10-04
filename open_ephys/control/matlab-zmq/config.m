% Please edit this file with the correct paths for ZMQ instalation.
%
% Examples can be found in files `config_unix.m`, `config_win.m`.
% This file itself shows how to build `matlab-zmq` using a Homebrew
% installation of ZMQ 4.3.4 for OS-X.

% ZMQ library filename
ZMQ_COMPILED_LIB = 'libzmq.dylib';

% ZMQ library path
% ZMQ_LIB_PATH = '/usr/lib/x86_64-linux-gnu/'; 
ZMQ_LIB_PATH = '/usr/local/Cellar/zeromq/4.3.4/lib/';

% ZMQ headers path
% ZMQ_INCLUDE_PATH = '/usr/include/'; 
ZMQ_INCLUDE_PATH = '/usr/local/Cellar/zeromq/4.3.4/include/';