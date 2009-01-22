#!/usr/bin/perl -w

################################################################################
#
#  The Scalable Environment for VErsatile Neural Networks
#
#  Sevenn/Function.pm - the library of function functions
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

package Sevenn::Function;

use strict;

###
# sub execute()
#   runs some segment of NNQL code
#   takes only the code (a scalar)
#   returns a table of the outcome values
###
sub execute{
  my ($self,$CONF,$nnl) = @_;

  if(lc($nnl) =~ '^show function'){
    return showFunctions($CONF,$nnl);
  }elsif(lc($nnl) =~ '^create function'){
    return createFunction($CONF,$nnl);
  }elsif(lc($nnl) =~ '^alter function'){
    return alterFunction($CONF,$nnl);
  }elsif(lc($nnl) =~ '^delete function'){
    return deleteFunction($CONF,$nnl);
  }
}


###
# sub showFunctions()
#   Takes a configuration hash and a nnql query to parse
#   Returns a status string;
###
sub showFunctions{
  my ($CONF,$nnl) = @_;

  ### Buld a list of all the functions and add them to the table
  my $functions = 0;
  my $table = Text::Table->new( "Title","Function","Variable" );
  my $csr = $$CONF{DBH}->prepare("select title, function, dependent_var from function;");
  if($csr->execute()){
    while(my $ref = $csr->fetchrow_hashref()){
      $functions++;
      $table->load([$$ref{title},$$ref{function},$$ref{dependent_var}]);
    }
  }else{
    return $csr->errstr;
  }

  ### If we have anything to show for it, show it.  If not, say so.
  if($functions){
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
    return "No functions loaded.";
  }
}


###
# sub createFunction()
#   takes a configuration hash and a nnql query to parse
#   returns a status string
###
sub createFunction{
my ($CONF, $nnl) = @_;
  if(lc($nnl) =~ /create function (\S*) value (\S*) variable (\S*)/){
    my ($function,$value,$variable);
    ($function,$value,$variable) = ($1,$2,$3);


    $value =~ s/^\'//;
    $value =~ s/\'$//;
    $variable =~ s/^\'//;
    $variable =~ s/\'$//g;

    ### Make sure there isn't already a function there by that name
    my $csr = $$CONF{DBH}->prepare("select function_id from function where title='$function'");
    if($csr->execute()){
      while (my $ref = $csr->fetchrow_hashref()){
        return "there is already a function called '$function'." 
      }
    }

    ### Create the function
    $csr = $$CONF{DBH}->prepare("insert into function (title, function, dependent_var)".
       " values ('$function','$value','$variable')");
    if($csr->execute()){
      return "function $function created successfully with value $value and variable $variable.";
    }else{
      return $csr->errstr();
    }

  }else{
    return "usage: create function (function name) value (function data) variable (dependent variable)";
  }
}


###
# sub alterFunction()
#   Takes the configuration hash and requisite nnql to parse
#   Returns a status string
###
sub alterFunction{
  my ($CONF, $nnl) = @_;
  if(lc($nnl) =~ /alter function (\S*)/){
    my ($function);
    ($function) = ($1);

    ### Get the function_id for the function they're talking about
    my $function_id=0;
    my $csr = $$CONF{DBH}->prepare("select function_id from function where title='$function'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $function_id=$$ref{function_id};
      }
    }
    return "$function isn't a valid function" unless $function_id;

    ### Initialize the new settings hashes
    my $newSettings = {};

    if(lc($nnl) =~ /value (\S*)/){
      $$newSettings{function}=$1;
    }
    if(lc($nnl) =~ /variable (\S*)/){
      $$newSettings{dependent_var}=$1;
    }

    ### Make the update call
    my $settings = join(', ',map("$_ = '$$newSettings{$_}'", keys(%$newSettings )));
    my $sql = "update function set $settings where function_id='$function_id'";
    $csr = $$CONF{DBH}->prepare($sql);
    if($csr->execute()){
      return "Function $function updated to $settings.";
    }else{
      return $csr->errstr;
    }
       
  }else{
    return "usage: alter function (function_name) change (value (function value)) (variable (dependent variable))";  
  }
}


###
# sub deleteFunction()
#   Takes the configuration hash and requisite nnql to parse
#   Returns a status string
###
sub deleteFunction{
  my ($CONF, $nnl) = @_;
  if(lc($nnl) =~ /delete function (\S*)/){
    my ($function);
    ($function) = ($1);

    ### Get the function_id for the function title they're talking about
    my $function_id=0;
    my $csr = $$CONF{DBH}->prepare("select function_id from function where title='$function'");
    if($csr->execute()){
      while(my $ref = $csr->fetchrow_hashref()){
        $function_id=$$ref{function_id};
      }
    }
    return "$function isn't a valid function" unless $function_id;

    ### Delete the records from the requisite table
    $csr = $$CONF{DBH}->prepare("delete from function where function_id='$function_id'");
    if($csr->execute()){
      return "Function $function deleted.";
    }else{
      return $csr->errstr;
    }
  }else{
    return "usage: delete function (function name)";
  }
}


1;
