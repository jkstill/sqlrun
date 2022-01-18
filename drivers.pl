#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Data::Dumper;

my @driver_names = DBI->available_drivers;

print '@driver_names: ' . Dumper(\@driver_names);
print "\n";

