package AutoDocTest1;

use Moose;

has attr1 => (is => 'ro');
has attr2 => (is => 'rw', isa => 'HashRef');
has attr3 => (is => 'rw', isa => 'ArrayRef[Str]');
has attr4 => (is => 'rw', isa => 'ArrayRef[Str]', required => 1);
has attr5 => (is => 'rw', isa => 'ArrayRef[Str]', required => 1, auto_deref => 1);
has attr6 => (is => 'rw', lazy_build => 1);
has attr7 => (reader => 'attr7', writer => '_attr7');

sub foo {

}

sub bar {

}

1;
