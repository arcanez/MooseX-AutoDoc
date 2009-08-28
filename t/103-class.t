#!/usr/bin/perl -w

use strict;
use warnings;
use MooseX::AutoDoc;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More tests => 1;

my $autodoc = MooseX::AutoDoc->new;
my $spec = $autodoc->_package_info("AutoDocTest4");

my $target = {
              name => 'AutoDocTest4',
              roles => [
                        { name => 'AutoDocTest::Role::Role1'} ,
                        { name => 'AutoDocTest::Role::Role2' }
                       ],
              superclasses => [
                              {name => 'AutoDocTest4BaseA'},
                              {name => 'AutoDocTest4BaseB'}
                             ],
              methods => [],
              attributes => []
             };

is_deeply($spec, $target);
