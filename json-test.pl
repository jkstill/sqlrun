#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use JSON::PP; # core package since Perl 5.14

use 5.14.0;

my $json = JSON::PP->new;

undef $/; # slurp mode for file read

my $jsonTxt=<STDIN>;



