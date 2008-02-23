#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
  use_ok( 'MooseX::AutoDoc' );
  use_ok( 'MooseX::AutoDoc::View' );
  use_ok( 'MooseX::AutoDoc::View::TT' );
}
