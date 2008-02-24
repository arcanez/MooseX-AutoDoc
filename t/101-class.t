#!/usr/bin/perl -w

use strict;
use warnings;
use MooseX::AutoDoc;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More tests => 1;

my $autodoc = MooseX::AutoDoc->new;
my $spec = $autodoc->_package_info("AutoDocTest2");

my $target = {
               name => 'AutoDocTest2',
               roles => [],
               superclasses => [{name => 'AutoDocTest1'}],
               methods => [{ name => 'bar'}],
               attributes =>
               [{
                 info => {'reader' => 'attr8', 'writer' => '_attr8'},
                 description => 'Optional value',
                 name => 'attr8',
                }]
              };
is_deeply($target, $spec);
