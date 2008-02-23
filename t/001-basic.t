#!/usr/bin/perl -w

use strict;
use warnings;
use MooseX::AutoDoc;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More tests => 6;

BEGIN{
  use_ok("AutoDocTest1");
}

ok(
   defined(my $autodoc = eval {MooseX::AutoDoc->new}),
   "Was instantiated successfully"
  );
die "Failed to instantiate MooseX::AutoDoc" unless $autodoc;

ok(
   defined(my $view = eval {$autodoc->view}),
   "Was instantiated successfully"
  );
die "Failed to instantiate MooseX::AutoDoc::View::TT" unless $view;
can_ok $view, "render_class", "render_role";

ok length($view->role_template),  "Role template appears to have been loaded successfully";
ok length($view->class_template), "Class template appears to have been loaded successfully";
