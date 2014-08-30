#!/usr/bin/perl -w

###
# SevennSrv.pl - The Sevenn server
###

################################################################################
#
#  The Scalable Environment for VErsatile Neural Networks
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

use strict;                  ### Used to keep code sane
use Sevenn;                  ### Used to interface with Sevenn Engine
use SOAP::Transport::HTTP;   ### Used to communicate over the network

### Initialize the SOAP server object
SOAP::Transport::HTTP::CGI->dispatch_to('Sevenn')->handle();
