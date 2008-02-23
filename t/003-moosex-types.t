#!/usr/bin/perl -w

use strict;
use warnings;
use MooseX::AutoDoc;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Class::MOP;

my $has_mx_types = eval { Class::MOP::load_class("MooseX::Types"); };
unless($has_mx_types) {
  plan skip_all => 'MooseX::Types is required for this test';
  exit;
}

Class::MOP::load_class("AutoDocTest7");
plan tests => 1;
my $autodoc = MooseX::AutoDoc->new;
my $attr = AutoDocTest7->meta->get_attribute("typed_attr");
my $spec = $autodoc->attribute_info($attr);
my $target = 'Optional value of type L<TestType\|AutoDocTestTypes';

like $spec->{description}, qr/$target/;

