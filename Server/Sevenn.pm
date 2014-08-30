#!/usr/bin/perl -w

################################################################################
#
#  The Scalable Environment for VErsatile Neural Networks
#
#  Sevenn.pm - the central library of sevenn functions
#
#  Copyright (c) 2004 by Danne Stayskal <danne@stayskal.com>.  
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA 02111-1307 USA
#
################################################################################

package Sevenn;

use strict;
use Config::IniHash;         ### Used to read configuration
use DBI;                     ### Used to store caches and data
use Text::Table;             ### Used for formatting output

use Sevenn::Node;            ### Node handling routines
use Sevenn::Edge;            ### Edge handling routines
use Sevenn::Function;        ### Function handling routines
use Sevenn::Network;         ### Network and run handling routines

my $inifile = '/etc/sevenn.ini';

###
# sub execute()
#   runs some segment of NNQL code
#   takes only the code (a scalar)
#   returns a table of the outcome values
###
sub execute{
  my ($self,$nnl) = @_;
  my $CONF = init();

  if(lc($nnl) =~ /(show|create|alter|delete|run) network/){
    return Sevenn::Network->execute($CONF,$nnl);
  }elsif(lc($nnl) =~ /(set|show|create|alter|delete) node/){
    return Sevenn::Node->execute($CONF,$nnl);
  }elsif(lc($nnl) =~ /(show|create|alter|delete) edge/){
    return Sevenn::Edge->execute($CONF,$nnl);
  }elsif(lc($nnl) =~ /(show|create|alter|delete) function/){
    return Sevenn::Function->execute($CONF,$nnl);
  }else{
    return "Syntax error in $nnl";
  }
}

###
# sub init()
#   initalizes sevennd server for communication with the outside world
#   takes nothing, returns Configuration hash
###
sub init{

  ### Create the local object
  my $srv = shift;
  #my $class = ref($srv) || $srv;
  #bless $srv, $class;
  #bless &version, $class;

  ### Turn on autoflushing (to log status realtime)
  $| = 1;

  ### Get global configuration options
  my $CONF = ReadINI($inifile) || die "Can't open coonfiguration file $inifile!\n";

  ### Open the log file
  #open($$self{'LOG'},">>$$CONF{server}{logfile}")||die "Can't open log file $$CONF{server}{logfile}!\n";

  ### Initialize the database connection
  $$CONF{'DBH'} =  DBI->connect("DBI:mysql:$$CONF{mysql}{database}:$$CONF{mysql}{host}",
     $$CONF{mysql}{username}, $$CONF{mysql}{password});

  return $CONF;
}

### Version and Inheritance control
sub version ($) { return "Sevenn Neural Network Daemon version 0.1\nRunning as pid $$ by user $< on ".`uname -n` }

1;
