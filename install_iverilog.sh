#/bin/bash

inst_dir=$HOME/iverilog

#use this script to install from source in a local directory (no need for root
#access). If the install directory is changed from the default above, make sure 
#to update common/include.mk PATH variable accordingly or have the new path/bin
#area in your path

ver=20150513
wget ftp://ftp.icarus.com/pub/eda/verilog/snapshots/pre-v10/verilog-$ver.tar.gz 
tar xvfz verilog-$ver.tar.gz
cd verilog-$ver
./configure --prefix=$inst_dir && make && make install
cd ..
rm -rf verilog-$ver
rm -f verilog-$ver.tar.gz