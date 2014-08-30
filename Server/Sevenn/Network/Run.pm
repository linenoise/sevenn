#!/usr/bin/perl -w

################################################################################
#
#  The Scalable Environment for VErsatile Neural Networks
#
#  Sevenn/Network/Run.pm - the central network running library of sevenn functions
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

package Sevenn::Network::Run;
use strict;
use Math::Symbolic qw/:all/;

sub Run{
  my ($self, $CONF, $network, $steps) = @_;

  ### Get the network_id for the network title they're talking about
  my $network_id = getNetworkId($CONF,$network);

  return "$network isn't a valid network" unless $network_id;

  ### Build the caches
  my $nodes = buildNodeCache($CONF,$network_id);
  my $edges = buildEdgeCache($CONF,$network_id);
  my $functions = buildFunctionCache($CONF,$nodes,$edges);

  ### Compile the functions into subroutines
  foreach my $function_id (sort(keys(%$functions))){
    my $expression = $$functions{$function_id}{function};
    my $tree = Math::Symbolic->parse_from_string($expression);
    return "Expression '$expression' is invalid ".
      "(from function '$$functions{$function_id}{title}')"
      unless length(scalar($tree));
    ($$functions{$function_id}{subroutine}) =
      Math::Symbolic::Compiler->compile_to_sub($tree);
  }

  ### Initialize the output table
  my $str = '';
  my @nodeTitles;
  my $nodeIndex = {};
  foreach my $node (keys(%$nodes)){
    push @nodeTitles, $node;
    $$nodeIndex{$$nodes{$node}{node_id}} = $$nodes{$node}{title};
  }
  
  @nodeTitles = sort @nodeTitles;
  my $table = Text::Table->new( "Step", @nodeTitles );
  foreach my $step (1..$steps){

    ### Build the step increment buffer
    my $newEdgeVals;
    my $newNodeVals;

    ### Iterate all the edges going to this node, calculate the total inputs to each node
    foreach my $node (%$nodes){ 
      foreach my $edge (%$edges){
        if($$edges{$edge}{to_node} && $$nodes{$node}{node_id} && $$edges{$edge}{to_node} == $$nodes{$node}{node_id}){

          ### Detemine if the edges are step-based or variable-based
          if($$functions{$$edges{$edge}{weight_function}}{dependent_var} eq 'step'){

            ### If they're step-based, add weight(step) to the new value for that node
            my $delta = $$functions{$$edges{$edge}{weight_function}}{subroutine}->($step);
            $$nodes{$$nodeIndex{$$edges{$edge}{from_node}}}{value} = sprintf('%1d',$delta);
            $$newNodeVals{$$nodes{$node}{node_id}} ||=0;
            $$newNodeVals{$$nodes{$node}{node_id}} += $delta;

          }else{

            ### If they're variable-based, add weight(from_node) to the new value for that node
            $$nodes{$$edges{$edge}{from_node}}{value} ||= 0;
            my $delta = $$functions{$$edges{$edge}{weight_function}}{subroutine}->(
              $$nodes{$$nodeIndex{$$edges{$edge}{from_node}}}{value}
            ); 
            $$newNodeVals{$$nodes{$node}{node_id}} ||=0;
            $$newNodeVals{$$nodes{$node}{node_id}} += $delta;

          }
        }
      }  
    }
    
    ### Add the row of current values to the output table
    my $row = [$step];
    foreach my $nodeTitle (@nodeTitles){
      $$nodes{$nodeTitle}{value} ||= 0;
      push @$row, $$nodes{$nodeTitle}{value};
    }
    $table->load($row);


    ### Iterate through all the nodes, update whether the input is enough to trigger them
    foreach my $node (%$nodes){
      next unless $$nodes{$node}{node_id};
      $$newNodeVals{$$nodes{$node}{node_id}} ||= 0;  ### to clear the input nodes for computation
      my $triggered = $$functions{$$nodes{$node}{activation_function}}{subroutine}->(
              $$newNodeVals{$$nodes{$node}{node_id}}
      );
      if(int($triggered)>0){
         ### Update the database to reflect a positive value
#         $str .= "  Looks like that was enough to trigger $$nodes{$node}{title}!\n";
         $$nodes{$node}{value} = 1;
      }else{
         ### Update the database to reflect a neutral value
         $$nodes{$node}{value} = 0;
      }
    }

  }
  if($steps){
    $table->body_rule('|');
    $table->rule('-');
    return $str.join('',
      $table->rule(qw/- +/),
      $table->title(),
      $table->rule(qw/- +/),
      $table->body(),
      $table->rule(qw/- +/)
    );
  }else{
    return "No steps run.";
  }
}


###
# sub buildFunctionCache
#   Takes a configuration hash and hashes of caches of nodes and edges
#   Returns a hash of all functions dealing with a set of nodes and edges
###
sub buildFunctionCache{
  my ($CONF,$nodes,$edges) = @_;
  my $function_ids = {};

  ### Figure out which functions we need
  foreach my $node (sort(keys(%$nodes))){
    $$function_ids{$$nodes{$node}{activation_function}} = 1;
  }
  foreach my $edge (sort(keys(%$edges))){
    $$function_ids{$$edges{$edge}{weight_function}} = 1;
  }

  my $where = join(' or ',map("function_id = $_",keys(%$function_ids)));
  
  ### Build the cache
  my $functions;
  my $csr = $$CONF{DBH}->prepare("select * from function where $where");
  if($csr->execute()){
    while(my $ref = $csr->fetchrow_hashref()){
      $$functions{$$ref{function_id}} = $ref;
    }
  }
  return $functions;
}


###
# sub buildEdgeCache
#   Takes a configuration hash and a network ID
#   Returns a hash of all edges in that network
###
sub buildEdgeCache{
  my ($CONF,$network_id) = @_;
  my $edges;
  my $csr = $$CONF{DBH}->prepare("select * from edge where in_network=$network_id");
  if($csr->execute()){
    while(my $ref = $csr->fetchrow_hashref()){
      $$edges{$$ref{title}} = $ref;
    }
  }
  return $edges;
}


###
# sub buildNodeCache
#   Takes a configuration hash and a network ID
#   Returns a hash of all nodes in that network
###
sub buildNodeCache{
  my ($CONF,$network_id) = @_;
  my $nodes;
  my $csr = $$CONF{DBH}->prepare("select * from node where in_network=$network_id");
  if($csr->execute()){
    while(my $ref = $csr->fetchrow_hashref()){
      $$nodes{$$ref{title}} = $ref;
    }
  }
  return $nodes;
}


###
# sub getNetworkId
#   Takes a configuration hash and a network name
#   Returns the network ID for that network name
###
sub getNetworkId{
  my ($CONF,$network) = @_;
  
  ### Get the network_id for the network title they're talking about
  my $network_id=0;
  my $csr = $$CONF{DBH}->prepare("select network_id, type from network where title='$network'");
  if($csr->execute()){
    while(my $ref = $csr->fetchrow_hashref()){
      $network_id=$$ref{network_id};
    }
  }
  return $network_id;
}


1;
