#!/usr/bin/perl -w

################################################################################
#
#  The Scalable Environment for VErsatile Neural Networks
#
#  Sevenn/Network.pm - the library of network functions
#
#  Copyright (c) 2004 by Dann Stayskal <dann@stayskal.com>.  
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

package Sevenn::Network;

use strict;

###
# sub execute()
#   runs some segment of NNQL code
#   takes only the code (a scalar)
#   returns a table of the outcome values
###
sub execute{
  my ($self,$CONF,$nnl) = @_;

  if(lc($nnl) eq 'show networks'){
    return showNetworks($CONF);
  }elsif(lc($nnl) =~ '^create network'){
    return createNetwork($CONF,$nnl);
  }elsif(lc($nnl) =~ '^delete network'){
    return deleteNetwork($CONF,$nnl);
  }elsif(lc($nnl) =~ '^alter network'){
    return alterNetwork($CONF,$nnl);
  }elsif(lc($nnl) =~ '^run network'){
    return runNetwork($CONF,$nnl);
  }
}


###
# sub runNetwork()
#   takes a configuration hash and the NNQL to be parsed
#   returns a status string
###
sub runNetwork{
  my ($CONF, $nnl) = @_;
  use Sevenn::Network::Run;
  if(lc($nnl) =~ /run network (\S*) steps (\S*)/){
    my ($network, $steps);
    ($network, $steps) = ($1,$2);
    return Sevenn::Network::Run->Run($CONF,$network,$steps);
  }else{
    return "usage: run network (network name) steps (steps)";
  }
}


###
# sub alterNetwork()
#   takes a configuration hash and the NNQL to be parsed
#   returns a status string
###
sub alterNetwork{
  my ($CONF, $nnl) = @_;
  if(lc($nnl) =~ /alter network (\S*)/){
    my $network;
    $network = $1;

    ### Get the network_id for the network title they're talking about
    my $network_id=0;
    my $type = '';
    my $csr = $$CONF{DBH}->prepare("select network_id, type from network where title='$network'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $network_id=$$ref{network_id};
        $type = $$ref{type};
      }
    }
    return "$network isn't a valid network" unless $network_id;

    if(lc($nnl) =~ /type (iterative|differential)/){
      my $type;
      $type = $1;
      $csr = $$CONF{DBH}->prepare("update network set type='$type' where network_id='$network_id'");
      if($csr->execute()){
        return "Network $network updated to type $type.";
      }else{
        return $csr->errstr;
      }
    }else{
      return "usage: alter network (network_name) change type (differential|iterative)";  
    }    
  }else{
    return "usage: alter network (network_name) change type (differential|iterative)";
  }
}


###
# sub deleteNetwork()
#  takes a configuration hash and the NNQL to be parsed
#  returns a status string
###
sub deleteNetwork{
  my ($CONF,$nnl) = @_;
  if(lc($nnl) =~ /delete network (\S*)/){
    my $network;
    $network = $1;

    ### Get the network_id for the network title they're talking about
    my $network_id=0;
    my $type = '';
    my $csr = $$CONF{DBH}->prepare("select network_id, type from network where title='$network'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $network_id=$$ref{network_id};
        $type = $$ref{type};
      }
    }
    return "$network isn't a valid network" unless $network_id;

    ### Delete the records from the requisite tables
    $csr = $$CONF{DBH}->prepare("delete from network where network_id='$network_id'");
    if($csr->execute()){
      $csr = $$CONF{DBH}->prepare("delete from node where in_network='$network_id'");
      if($csr->execute()){
        $csr = $$CONF{DBH}->prepare("delete from edge where in_network='$network_id'");
        if($csr->execute()){
          return "$type network $network deleted.";
        }else{
          return $csr->errstr;
        }
      }else{
        return $csr->errstr;
      }
    }else{
      return $csr->errstr;
    }
  }else{
    return "usage: delete network (network name)";
  }
}


###
# sub createNetwork()
#  takes a configuration hash and the NNQL to be parsed
#  returns text string of status
###
sub createNetwork{
  my ($CONF,$nnl) = @_;
  if(lc($nnl) =~ /create network (\S*)/){
    my $name;
    $name = $1;

    ### Make sure there isn't a network already called this...
    my $csr = $$CONF{DBH}->prepare("select network_id from network where title='$name'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        return "there is already a network called $name.";
      }
    }

    ### Figure out the network type
    my $type = 'differential';   # default
    if(lc($nnl) =~ /of type (\S*)/){
      if($1 =~ /(differential|iterative)/){
        $type = $1
      }else{
        return "networks may only be differential, or iterative";
      }
    }

    ### Create the network object
    $csr = $$CONF{DBH}->prepare("insert into network (title,network_id,type) values('$name','','$type')");
    if(!($csr->execute())){
      return $csr->errstr;
    }

    ### Find out which network_id the database assigned to that object
    my $network_id = 0;
    $csr = $$CONF{DBH}->prepare("select network_id from network where title='$name'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $network_id = $$ref{network_id};
      }
    }
    return "Internal error - can't get network_id!" unless $network_id;

    ### All went well.
    return "$type network $name created.";
  }else{
    return "usage: create network (network name) [of type (network type)]";
  }
}


###
# sub showNetworks()
#   takes a configuration hash
#   returns a table of current networks or text string of status if none found
###
sub showNetworks{
  my $CONF = shift;
  my $table = Text::Table->new( "Network", "Type", "Nodes", "Edges" );
  my ($nodes,$edges,$networks,$csr);

  ### Build a local list of how many nodes are in each network
  $csr = $$CONF{DBH}->prepare('select in_network, count(in_network) as total from node group by in_network');
  if($csr->execute()){
    while(my $ref = $csr->fetchrow_hashref()){
      $$nodes{$$ref{in_network}} = $$ref{total}
    }
  }

  ### Build a local list of how many edges are in each network
  $csr = $$CONF{DBH}->prepare('select in_network, count(in_network) as total from edge group by in_network');
  if($csr->execute()){
    while(my $ref = $csr->fetchrow_hashref()){
      $$edges{$$ref{in_network}} = $$ref{total}
    }
  }

  ### Buld a local list of all the networks and add them to the table with their node and edge counts
  $csr = $$CONF{DBH}->prepare('select title, type, network_id from network');
  if($csr->execute()){
    while(my $ref = $csr->fetchrow_hashref()){
      $networks++;
      $table->load([$$ref{title},$$ref{type},int($$nodes{$$ref{network_id}}),int($$edges{$$ref{network_id}})]);
    }
  }

  ### If we have anything to show for it, show it.  If not, say so.
  if($networks){
    $table->body_rule('|');
    $table->rule('-');
    return join('', $table->rule(qw/- +/), $table->title(), $table->rule(qw/- +/), $table->body(), $table->rule(qw/- +/));
  }else{
    return "no networks loaded.";
  }
}

1;
