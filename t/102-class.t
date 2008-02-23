#!/usr/bin/perl -w

use strict;
use warnings;
use MooseX::AutoDoc;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More tests => 1;

my $autodoc = MooseX::AutoDoc->new;
my $spec = $autodoc->class_info("AutoDocTest3");

my $target = {
               name => 'AutoDocTest3',
               roles => [ { name => 'AutoDocTest::Role::Role1' } ],
               superclasses => [{name => 'AutoDocTest2'}],
               methods => [],
               attributes => [],
              };

is_deeply($target, $spec);
