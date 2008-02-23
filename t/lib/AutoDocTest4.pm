package AutoDocTest4;
use Moose;

extends 'AutoDocTest4BaseA','AutoDocTest4BaseB';

with 'AutoDocTest::Role::Role1', 'AutoDocTest::Role::Role2';

package AutoDocTest4BaseA;
use Moose;

1;

package AutoDocTest4BaseB;
use Moose;

1;
