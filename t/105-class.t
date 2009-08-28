#!/usr/bin/perl -w

use strict;
use warnings;
use MooseX::AutoDoc;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More tests => 1;

my $autodoc = MooseX::AutoDoc->new;
my $spec = $autodoc->_package_info("AutoDocTest6");

my $target = {
              name => 'AutoDocTest6',
              roles => [{ name => 'AutoDocTest::Role::Role3'}],
              superclasses => [],
              methods => [],
              attributes => [],
             };

is_deeply($spec, $target);
