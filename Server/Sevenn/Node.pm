#!/usr/bin/perl -w

################################################################################
#
#  The Scalable Environment for VErsatile Neural Networks
#
#  Sevenn/Node.pm - the library of node functions
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


package Sevenn::Node;

use strict;

###
# sub execute()
#   runs some segment of NNQL code
#   takes only the code (a scalar)
#   returns a table of the outcome values
###
sub execute{
  my ($self,$CONF,$nnl) = @_;

  if(lc($nnl) =~ '^show node'){
    return showNodes($CONF,$nnl);
  }elsif(lc($nnl) =~ '^create node'){
    return createNode($CONF,$nnl);
  }elsif(lc($nnl) =~ '^alter node'){
    return alterNode($CONF,$nnl);
  }elsif(lc($nnl) =~ '^delete node'){
    return deleteNode($CONF,$nnl);
  }elsif(lc($nnl) =~ '^set node'){
    return setNode($CONF,$nnl);
  }
}



###
# sub setNode()
#   Takes the configuration hash and requisite nnql to parse
#   Returns a status string
###
sub setNode{
  my ($CONF, $nnl) = @_;
  if(lc($nnl) =~ /set node (\S*) in network (\S*) value (\S*)/){
    my ($node, $network, $value);
    ($node, $network, $value) = ($1, $2, $3);

    ### Get the network_id for the network title they're talking about
    my $network_id=0;
    my $csr = $$CONF{DBH}->prepare("select network_id from network where title='$network'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $network_id=$$ref{network_id};
      }
    }
    return "$network isn't a valid network" unless $network_id;

    ### Get the node_id for the node they're talking about
    my $node_id=0;
    $csr = $$CONF{DBH}->prepare("select node_id from node where title='$node'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $node_id=$$ref{node_id};
      }
    }
    return "$node isn't a valid node" unless $node_id;

    ### Set the node value;
    $csr = $$CONF{DBH}->prepare("update node set value='$value' where node_id='$node_id'");
    if($csr->execute()){
      return "Node $node in network $network set to value $value";
    }else{
      return $csr->errstr;  
    }
    
  }else{
    return "usage: alter node (node_name) change activation (function name)";  
  }
}


###
# sub showNodes()
#   Takes a configuration hash and a nnql query to parse
#   Returns a status string;
###
sub showNodes{
  my ($CONF,$nnl) = @_;
  if(lc($nnl) =~ '^show nodes'){
    if(lc($nnl) =~ /show nodes from (\S*)/){
      my $network;
      $network = $1;

      ### Get the network_id for the network title they're talking about
      my $network_id=0;
      my $csr = $$CONF{DBH}->prepare("select network_id from network where title='$network'");
      if($csr->execute()){
        while(my $ref = $csr->fetchrow_hashref()){
          $network_id=$$ref{network_id};
        }
      }
      return "$network isn't a valid network" unless $network_id;


      ### Buld a list of all the nodes and add them to the table
      my $nodes = 0;
      my $table = Text::Table->new( "Node","Value","Function" );
      $csr = $$CONF{DBH}->prepare("select node.title as name, node.value as value, function.title as func from node ".
        "left join function on node.activation_function=function.function_id where node.in_network=$network_id");
      if($csr->execute()){
        while(my $ref = $csr->fetchrow_hashref()){
          $nodes++;
          $table->load([$$ref{name},$$ref{value},$$ref{func}]);
        }
      }

      ### If we have anything to show for it, show it.  If not, say so.
      if($nodes){
        $table->body_rule('|');
        $table->rule('-');
        return join('',
          $table->rule(qw/- +/),
          $table->title(),
          $table->rule(qw/- +/),
          $table->body(),
          $table->rule(qw/- +/)
        );
     }else{
       return "no nodes in $network";
     }
    }else{
      return "usage: show nodes from (network name)";
    }
  }
}


###
# sub createNode()
#   takes a configuration hash and a nnql query to parse
#   returns a status string
###
sub createNode{
my ($CONF, $nnl) = @_;
  if(lc($nnl) =~ '^create node'){
    if(lc($nnl) =~ /create node (\S*) in network (\S*)/){
      my ($node,$network);
      ($node,$network) = ($1,$2);

      ### Get the network_id for the network title they're talking about
      my $network_id=0;
      my $csr = $$CONF{DBH}->prepare("select network_id from network where title='$network'");
      if($csr->execute()){
        while(my $ref = $csr->fetchrow_hashref()){
          $network_id=$$ref{network_id};
        }
      }
      return "$network isn't a valid network" unless $network_id;

      ### Make sure there isn't already a node there by that name
      $csr = $$CONF{DBH}->prepare("select node_id from node where title='$node' and in_network='$network_id'");
      if($csr->execute()){
        while (my $ref = $csr->fetchrow_hashref()){
          return "there is already a node called '$node' in network '$network'." 
        }
      }

      ### if they specified an activation function
      if(lc($nnl) =~ /activation (\S*)/){
        my $function;
        $function = $1;

        ### Get the function_id for the function they're talking about
        my $function_id=0;
        my $csr = $$CONF{DBH}->prepare("select function_id from function where title='$function'");
        if($csr->execute()){
          while(my $ref = $csr->fetchrow_hashref()){
            $function_id=$$ref{function_id};
          }
        }
        return "$function isn't a valid function" unless $function_id;

        $csr = $$CONF{DBH}->prepare("insert into node (title, in_network, activation_function)".
           " values ('$node','$network_id','$function_id')");
        if($csr->execute()){
          return "node $node created successfully in $network with activation function $function.";
        }else{
          return $csr->errstr();
        }

      ### they didn't specify an activation function - create the node without one for now
      }else{
        $csr = $$CONF{DBH}->prepare("insert into node (title, in_network) values ('$node','$network_id')");
        if($csr->execute()){
          return "node $node created successfully in $network.";
        }else{
          return $csr->errstr;
        }
      }
    }else{
      return "usage: create node (node name) in network (network name)";
    }
  }else{
    return "Sorry, I don't know how to parse $nnl yet";
  }
}


###
# sub alterNode()
#   Takes the configuration hash and requisite nnql to parse
#   Returns a status string
###
sub alterNode{
  my ($CONF, $nnl) = @_;
  if(lc($nnl) =~ /alter node (\S*) in network (\S*)/){
    my ($node, $network);
    ($node, $network) = ($1, $2);

    ### Get the network_id for the network title they're talking about
    my $network_id=0;
    my $csr = $$CONF{DBH}->prepare("select network_id from network where title='$network'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $network_id=$$ref{network_id};
      }
    }
    return "$network isn't a valid network" unless $network_id;

    ### Get the node_id for the node they're talking about
    my $node_id=0;
    $csr = $$CONF{DBH}->prepare("select node_id from node where title='$node'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $node_id=$$ref{node_id};
      }
    }
    return "$node isn't a valid node" unless $node_id;

    if(lc($nnl) =~ /activation (\S*)/){
      my $function;
      $function = $1;
      ### Get the function_id for the function they're talking about
      my $function_id=0;
      my $csr = $$CONF{DBH}->prepare("select function_id from function where title='$function'");
      if($csr->execute()){
        while(my $ref = $csr->fetchrow_hashref()){
          $function_id=$$ref{function_id};
        }
      }
      return "$function isn't a valid function" unless $function_id;

      $csr = $$CONF{DBH}->prepare("update node set activation_function='$function_id' where node_id='$node_id'");
      if($csr->execute()){
        return "Node $node in network $network updated to function $function.";
      }else{
        return $csr->errstr;
      }
    }else{
      return "usage: alter node (node_name) change activation (function name)";  
    }    
  }else{
    return "usage: alter node (node_name) change activation (function name)";  
  }
}


###
# sub deleteNode()
#   Takes the configuration hash and requisite nnql to parse
#   Returns a status string
###
sub deleteNode{
  my ($CONF, $nnl) = @_;
  if(lc($nnl) =~ /delete node (\S*) from network (\S*)/){
    my ($network, $node);
    ($network, $node) = ($2,$1);

    ### Get the network_id for the network title they're talking about
    my $network_id=0;
    my $csr = $$CONF{DBH}->prepare("select network_id, type from network where title='$network'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $network_id=$$ref{network_id};
      }
    }
    return "$network isn't a valid network" unless $network_id;

    ### Get the node_id for the node title they're talking about
    my $node_id=0;
    $csr = $$CONF{DBH}->prepare("select node_id from node where title='$node' and in_network='$network_id'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $node_id=$$ref{node_id};
      }
    }
    return "$node isn't a valid node in $network" unless $node_id;

    ### Delete the records from the requisite tables
    $csr = $$CONF{DBH}->prepare("delete from node where node_id='$node_id' and in_network='$network_id'");
    if($csr->execute()){
      return "Node $node deleted from network $network.";
    }else{
      return $csr->errstr;
    }
  }else{
    return "usage: delete node (node name) from network (network name)";
  }
}


1;
