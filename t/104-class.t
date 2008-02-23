#!/usr/bin/perl -w

use strict;
use warnings;
use MooseX::AutoDoc;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More tests => 1;

my $autodoc = MooseX::AutoDoc->new;
my $spec = $autodoc->class_info("AutoDocTest5");

my $target = {
              name => 'AutoDocTest5',
              roles => [],
              superclasses => [{name => 'AutoDocTest3'}],
              methods => [],
              attributes => [],
              };

is_deeply($target, $spec);
