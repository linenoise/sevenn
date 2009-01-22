#!/usr/bin/perl -w

################################################################################
#
#  The Scalable Environment for VErsatile Neural Networks
#
#  Sevenn/Edge.pm - the library of edge functions
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

package Sevenn::Edge;

use strict;

###
# sub execute()
#   runs some segment of NNQL code
#   takes only the code (a scalar)
#   returns a table of the outcome values
###
sub execute{
  my ($self,$CONF,$nnl) = @_;

  if(lc($nnl) =~ '^show edge'){
    return showEdges($CONF,$nnl);
  }elsif(lc($nnl) =~ '^create edge'){
    return createEdge($CONF,$nnl);
  }elsif(lc($nnl) =~ '^alter edge'){
    return alterEdge($CONF,$nnl);
  }elsif(lc($nnl) =~ '^delete edge'){
    return deleteEdge($CONF,$nnl);
  }
}


###
# sub showEdges()
#   Takes a configuration hash and a nnql query to parse
#   Returns a status string;
###
sub showEdges{
  my ($CONF,$nnl) = @_;
  if(lc($nnl) =~ /show edges from (\S*)/){
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

      
    ### Buld a list of all the edges and add them to the table
    my $edges = 0;
    my $table = Text::Table->new( "Edge","From","To","Value","Function" );
    my $sql = <<__END_SQL__
      select
        edge.title as name, 
        edge.value as value, 
        function.title as func,
        fromnode.title as from_node,
        tonode.title as to_node from edge
      left join function on edge.weight_function=function.function_id 
      left join node as fromnode on edge.from_node=fromnode.node_id 
      left join node as tonode on edge.to_node=tonode.node_id 
      where edge.in_network=5
__END_SQL__
;
    $csr = $$CONF{DBH}->prepare($sql);
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $edges++;
        $table->load([$$ref{name},$$ref{from_node},$$ref{to_node},$$ref{value},$$ref{func}]);
      }
    }else{
      return $csr->errstr;
    }

    ### If we have anything to show for it, show it.  If not, say so.
    if($edges){
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
     return "no edges in $network";
   }
  }else{
    return "usage: show edges from (network name)";
  }
}


###
# sub createEdge()
#   takes a configuration hash and a nnql query to parse
#   returns a status string
###
sub createEdge{
my ($CONF, $nnl) = @_;
  if(lc($nnl) =~ '^create edge'){
    if(lc($nnl) =~ /create edge (\S*) in network (\S*) from node (\S*) to node (\S*) weight (\S*)/){
      my ($edge,$network,$from,$to,$weight);
      ($edge,$network,$from,$to,$weight) = ($1,$2,$3,$4,$5);

      ### Get the network_id for the network title they're talking about
      my $network_id=0;
      my $csr = $$CONF{DBH}->prepare("select network_id from network where title='$network'");
      if($csr->execute()){
        while(my $ref = $csr->fetchrow_hashref()){
          $network_id=$$ref{network_id};
        }
      }
      return "$network isn't a valid network" unless $network_id;

      ### Get the node_id for the network title they're talking about coming from
      my $from_node=0;
      $csr = $$CONF{DBH}->prepare("select node_id from node where title='$from' and in_network='$network_id'");
      if($csr->execute()){
        while(my $ref = $csr->fetchrow_hashref()){
          $from_node=$$ref{node_id};
        }
      }
      return "$from isn't a valid node in $network" unless $from_node;

      ### Get the node_id for the network title they're talking about goign to
      my $to_node=0;
      $csr = $$CONF{DBH}->prepare("select node_id from node where title='$to' and in_network='$network_id'");
      if($csr->execute()){
        while(my $ref = $csr->fetchrow_hashref()){
          $to_node=$$ref{node_id};
        }
      }
      return "$to isn't a valid node in $network" unless $to_node;

      ### Get the function_id for the network title they're talking about weighting by
      my $function_id=0;
      $csr = $$CONF{DBH}->prepare("select function_id from function where title='$weight'");
      if($csr->execute()){
        while(my $ref = $csr->fetchrow_hashref()){
          $function_id=$$ref{function_id};
        }
      }
      return "$weight isn't a valid function" unless $function_id;

      ### Make sure there isn't already a edge there by that name
      $csr = $$CONF{DBH}->prepare("select edge_id from edge where title='$edge' and in_network='$network_id'".
      " and from_node='$from_node' and to_node='to_node'");
      if($csr->execute()){
        while (my $ref = $csr->fetchrow_hashref()){
          return "there is already a edge called '$edge' in network '$network' from '$from' to '$to'." 
        }
      }

      ### Create the edge
      $csr = $$CONF{DBH}->prepare("insert into edge (title, in_network, from_node, to_node, weight_function) ".
        "values ('$edge','$network_id','$from_node','$to_node','$function_id')");
      if($csr->execute()){
        return "edge $edge created successfully in $network from $from to $to.";
      }else{
        return $csr->errstr;
      }
      
    }else{
      return "usage: create edge (edge name) in network (network name) from node (node name) ".
        "to node (node name) weight (function name)";
    }
  }else{
    return "Sorry, I don't know how to parse $nnl yet";
  }
}


###
# sub alterEdge()
#   Takes the configuration hash and requisite nnql to parse
#   Returns a status string
###
sub alterEdge{
  my ($CONF, $nnl) = @_;
  if(lc($nnl) =~ /alter edge (\S*) in network (\S*)/){
    my ($edge, $network);
    ($edge, $network) = ($1, $2);
    
    ### Get the network_id for the network title they're talking about
    my $network_id=0;
    my $csr = $$CONF{DBH}->prepare("select network_id from network where title='$network'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $network_id=$$ref{network_id};
      }
    }
    return "$network isn't a valid network" unless $network_id;

    ### Get the edge_id for the edge they're talking about
    my $edge_id=0;
    $csr = $$CONF{DBH}->prepare("select edge_id from edge where title='$edge'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $edge_id=$$ref{edge_id};
      }
    }
    return "$edge isn't a valid edge" unless $edge_id;

    ### Initialize the new settings hashes
    my $newSettings = {};
    my $settingsNames = {};

    ### Get the node_id for the network title they're talking about coming from
    if(lc($nnl) =~ /from node (\S*)/){
      my $from;
      $from = $1;
      my $csr = $$CONF{DBH}->prepare("select node_id from node where title='$from' and in_network='$network_id'");
      if($csr->execute()){
        while(my $ref = $csr->fetchrow_hashref()){
          $$newSettings{from_node}=$$ref{node_id};
          $$settingsNames{from_node}=$from;
        }
      }
      return "$from isn't a valid node in $network" unless $$newSettings{from_node};
    }

    ### Get the node_id for the network title they're talking about goign to
    if(lc($nnl) =~ /to node (\S*)/){
      my $to;
      $to = $1;
      my $csr = $$CONF{DBH}->prepare("select node_id from node where title='$to' and in_network='$network_id'");
      if($csr->execute()){
        while(my $ref = $csr->fetchrow_hashref()){
          $$newSettings{to_node}=$$ref{node_id};
          $$settingsNames{to_node} = $to;
        }
      }
      return "$to isn't a valid node in $network" unless $$newSettings{to_node};
    }

    ### Get the function_id for the network title they're talking about weighting by
    if(lc($nnl) =~ /weight (\S*)/){
      my $weight;
      $weight = $1;
      my $csr = $$CONF{DBH}->prepare("select function_id from function where title='$weight'");
      if($csr->execute()){
        while(my $ref = $csr->fetchrow_hashref()){
          $$newSettings{weight_function}=$$ref{function_id};
          $$settingsNames{weight_function}=$weight;
        }
      }else{
        return $csr->errstr;
      }
      return "$weight isn't a valid function" unless $$newSettings{weight_function};
    }

    return "Nothing to update" unless scalar(keys(%$newSettings));

    ### Make the update call
    my $settings = join(', ',map("$_ = '$$newSettings{$_}'", keys(%$newSettings )));
    my $sql = "update edge set $settings where edge_id='$edge_id'";
    $csr = $$CONF{DBH}->prepare($sql);
    if($csr->execute()){
      return "Edge $edge in network $network updated to ".
      join(', ',map("$_ = $$settingsNames{$_}", keys(%$settingsNames ))).".";
    }else{
      return $csr->errstr;
    }
  }else{
    return "usage: alter edge (edge_name) in network (network_name) change ".
      "(FROM NODE (from_node)) (TO NODE (to_node)) (WEIGHT (weight_function));";
  }
}


###
# sub deleteEdge()
#   Takes the configuration hash and requisite nnql to parse
#   Returns a status string
###
sub deleteEdge{
  my ($CONF, $nnl) = @_;
  if(lc($nnl) =~ /delete edge (\S*) from network (\S*)/){
    my ($network, $edge);
    ($network, $edge) = ($2,$1);

    ### Get the network_id for the network title they're talking about
    my $network_id=0;
    my $csr = $$CONF{DBH}->prepare("select network_id, type from network where title='$network'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $network_id=$$ref{network_id};
      }
    }
    return "$network isn't a valid network" unless $network_id;

    ### Get the edge_id for the edge title they're talking about
    my $edge_id=0;
    $csr = $$CONF{DBH}->prepare("select edge_id from edge where title='$edge' and in_network='$network_id'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $edge_id=$$ref{edge_id};
      }
    }
    return "$edge isn't a valid edge in $network" unless $edge_id;

    ### Delete the records from the requisite tables
    $csr = $$CONF{DBH}->prepare("delete from edge where edge_id='$edge_id'");
    if($csr->execute()){
      return "Edge $edge deleted from network $network.";
    }else{
      return $csr->errstr;
    }
  }else{
    return "usage: delete edge (edge name) from network (network name)";
  }
}


1;
