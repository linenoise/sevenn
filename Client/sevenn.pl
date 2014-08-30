#!/usr/bin/perl -w

################################################################################
#
#  The Scalable Environment for VErsatile Neural Networks
#
#  sevenn.pl - The standard sevenn client
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

use strict;                  ### All modules available on cpan.org
use SOAP::Lite;              ### For communication with the server
use Term::ReadKey;           ### For communication with the user
use Config::IniHash;         ### For configuration options
use subs qw/say warn error/; ### For internal communication

### Read in the local configuration
print ">>> Reading configuration file sevenn.ini\n";
my $CONF = ReadINI('/etc/sevenn.ini') || die "Can't open coonfiguration file /etc/sevenn.ini!\n";

### Connect to the server
say ">>> Connecting to the SEVENN server";
my $server = SOAP::Lite->uri($$CONF{server}{uri})->proxy($$CONF{server}{proxy});


### Entering interactive mode
say ">>> Entering interactive mode.  Type 'quit' to quit or 'help' for help.";
print $server->version()->result()."$$CONF{client}{prompt} ";

### Get input from the user
$| = 1;
my $continue = 1;
while($continue) {
  my $line = <STDIN>;
  last unless $line;
  chomp $line;
  $line =~ s/;$//;   ### strip terminal semicolons;
  if($line =~ /(quit|exit|logout)/){
    $continue = 0;
    last;
  }elsif($line =~ /help/){
    if(open('HELP',"<$$CONF{client}{helpfile}")){
      say join('',<HELP>);
    }else{
      say "Help isn't available at this time"
    } 
  }else{
    my $result = $server->execute($line)->result();
    chomp $result if $result;
    say ($result?$result:'No data returned');
  }
  print "\n$$CONF{client}{prompt} ";
}


### ### ### ###   S U B R O U T I N E S   ### ### ### ###

###
# sub say()
#   takes a message, writes it to the log, and prints it to STDOUT
#   returns nothing of value
###
sub say{
  my ($message) = @_;
  return unless $message;
  if(open('LOGFILE',">>$$CONF{client}{logfile}")){
    print LOGFILE "$message\n";
  }
  print "$message\n";
}

###
# sub error()
#   takes a message, writes it to the log, prints it to STDOUT, and dies
#   returns nothing of value
###
sub error{
  my ($message) = @_;
  say "Ouch - $message.  I die.\n";
  die;
}
