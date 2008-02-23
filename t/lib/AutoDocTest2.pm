package AutoDocTest2;

use Moose;

extends 'AutoDocTest1';

has attr8 => (reader => 'attr8', writer => '_attr8');

override bar => sub {

};

1;
