#!/usr/bin/perl -w

use strict;
use warnings;
use MooseX::AutoDoc;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More tests => 1;

my $autodoc = MooseX::AutoDoc->new;
my $spec = $autodoc->role_info("AutoDocTest::Role::Role3");

my $target = {
              name => 'AutoDocTest::Role::Role3',
              roles => [
                        {name => 'AutoDocTest::Role::Role1',},
                        {name => 'AutoDocTest::Role::Role2',}
                       ],
              methods => [{ name => 'role_3'}],
              attributes => [
                             {
                              name => 'role_3_attr',
                              info => {},
                              description => 'Optional read-write value'
                             },
                            ],
             };
is_deeply($target, $spec);
