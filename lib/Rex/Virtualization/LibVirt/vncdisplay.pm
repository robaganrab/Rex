#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Virtualization::LibVirt::vncdisplay;

use strict;
use warnings;

use Rex::Logger;
use Rex::Helper::Run;

use XML::Simple;

use Data::Dumper;

sub execute {
   my ($class, $vmname) = @_;

   unless($vmname) {
      die("You have to define the vm name!");
   }

   Rex::Logger::debug("Getting info of domain: $vmname");

   my $xml;

   my @vncdisplay = i_run "virsh vncdisplay $vmname";
  
   if($? != 0) {
      die("Error running virsh vncdisplay $vmname");
   }

   return shift @vncdisplay;
}

1;
