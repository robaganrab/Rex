#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Hal;

use Rex::Hal::Object;
use Rex::Commands::Run;
use Data::Dumper;

use strict;
use warnings;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   $self->_read_lshal();

   return $self;
}

# get devices of $category
# like net or storage
sub get_devices_of {

   my ($self, $cat) = @_;
   my @ret;

   for my $dev (keys %{ $self->{'__hal'}->{$cat} }) {
      push( @ret, $self->get_object_by_cat_and_udi($cat, $dev));
   }

   return @ret;
}

# get a hal object from category and udi
sub get_object_by_cat_and_udi {
   my ($self, $cat, $udi) = @_;

   my $class_name = "Rex::Hal::Object::\u$cat";
   eval "use $class_name";
   if($@) {
      Rex::Logger::debug("This Hal Object isn't supported yet. Falling back to Base Object.");
      $class_name = "Rex::Hal::Object";
   }

   return $class_name->new(%{$self->{'__hal'}->{$cat}->{$udi}}, hal => $self);
}

# get object by udi
sub get_object_by_udi {
   my ($self, $udi) = @_;

   for my $cat (keys %{$self->{'__hal'}}) {
      for my $dev (keys %{$self->{'__hal'}->{$cat}}) {
         if($dev eq $udi) {
            return $self->get_object_by_cat_and_udi($cat, $dev);
         }
      }
   }
}

# private method to read lshal output
# you don't see that...
sub _read_lshal {

   my ($self) = @_;

   my @lines = run "lshal";
   my %devices;
   my %tmp_devices;

   my $in_dev= 0;
   my %data;
   my $dev_name;

   for my $l (@lines) {
      chomp $l;

      if($l =~ m/^udi = '(.*?)'/) {
         $in_dev = 1;
         $dev_name = $1;
      }

      if($l =~ m/^$/) {
         $in_dev = 0;
         unless ($dev_name) {
            %data = ();
            next;
         }
         $tmp_devices{$dev_name} = { %data };
         %data = ();
      }

      if($in_dev) {
         my ($key, $val) = split(/ = /, $l, 2);
         $key =~ s/^\s+//;
         $key =~ s/^'|'$//g;
         $val =~ s/\(.*?\)$//;
         $val =~ s/^\s+//;
         $val =~ s/\s+$//;
         $val =~ s/^'|'$//g;
         $data{$key} = $val;
      }

   }


   for my $dev (keys %tmp_devices) {

      my $s_key = $tmp_devices{$dev}->{"info.subsystem"};
      $s_key ||= $tmp_devices{$dev}->{"info.category"};

      if(! $s_key) {
         #print Dumper($tmp_devices{$dev});
         next;
      }

      if(! exists $devices{$s_key}) {
         $devices{$s_key} = {};
      }

      $devices{$s_key}->{$dev} = $tmp_devices{$dev};

   }

   $self->{'__hal'} = \%devices;


}

1;