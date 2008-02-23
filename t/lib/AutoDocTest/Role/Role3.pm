package AutoDocTest::Role::Role3;

use Moose::Role;

with 'AutoDocTest::Role::Role1', 'AutoDocTest::Role::Role2';

has role_3_attr => (is => 'rw');

sub role_3{

}

1;
