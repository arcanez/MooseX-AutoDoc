#!/usr/bin/perl -w

use strict;
use warnings;
use MooseX::AutoDoc;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More tests => 1;

my $autodoc = MooseX::AutoDoc->new;
my $spec = $autodoc->_role_info("AutoDocTest::Role::Role1");

my $target = {
              name => 'AutoDocTest::Role::Role1',
              roles => [],
              methods => [{ name => 'role_1'}],
              attributes => [
                             {
                              name => 'role_1_attr',
                              info => {},
                              description => 'Optional read-write value'
                             },
                            ],
             };
is_deeply($target, $spec);
