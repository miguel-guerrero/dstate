#!/bin/bash

#To install vppreproc dependencies without root access
#-----------------------------------------------------

#see https://stackoverflow.com/questions/2980297/how-can-i-use-cpan-as-a-non-root-user

# get the latest version of cpan and configure it to build under ~/perl5
wget -O- http://cpanmin.us | perl - -l ~/perl5 App::cpanminus local::lib

eval `perl -I ~/perl5/lib/perl5 -Mlocal::lib`
echo 'eval `perl -I ~/perl5/lib/perl5 -Mlocal::lib`' >> ~/.profile
echo 'export MANPATH=$HOME/perl5/man:$MANPATH' >> ~/.profile

perl -MCPAN -e 'install Verilog::Preproc'
perl -MCPAN -e 'install Verilog::Getopt'

