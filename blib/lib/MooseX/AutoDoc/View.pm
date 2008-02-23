package MooseX::AutoDoc::View;

use Moose;

has args => (is => 'ro', predicate => 'has_args');

#twi different methods because it really does make more sense this way
sub render_role  { confess "Unimplemented Method"; }
sub render_class { confess "Unimplemented Method"; }

1;
