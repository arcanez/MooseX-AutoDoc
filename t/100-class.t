#!/usr/bin/perl -w

use strict;
use warnings;
use MooseX::AutoDoc;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More tests => 1;

my $autodoc = MooseX::AutoDoc->new;
my $spec = $autodoc->_class_info("AutoDocTest1");

#we already tested this..
delete $spec->{attributes};

my $target = {
               name => 'AutoDocTest1',
               roles => [],
               superclasses => [],
               methods => [{ name => 'bar'},{ name => 'foo'}],
              };
is_deeply($target, $spec);
